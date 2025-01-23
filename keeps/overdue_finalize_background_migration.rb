# frozen_string_literal: true

require_relative '../config/environment'
require_relative '../lib/generators/post_deployment_migration/post_deployment_migration_generator'
require_relative './helpers/postgres_ai'
require_relative 'helpers/groups'
require 'rubocop'

module Keeps
  # This is an implementation of a ::Gitlab::Housekeeper::Keep. This keep will locate any old batched background
  # migrations that were added before CUTOFF_MILESTONE and then check if they are finished by querying Postgres.ai
  # database archive. Once it has determined it is safe to finalize the batched background migration it will generate a
  # new migration which calls `ensure_batched_background_migration_is_finished` for this migration. It also updates the
  # `db/docs/batched_background_migrations` file with `finalized_by` and generates the `schema_migrations` file.
  #
  # This keep requires the following additional environment variables to be set:
  #  - POSTGRES_AI_CONNECTION_STRING: A valid postgres connection string
  #  - POSTGRES_AI_PASSWORD: The password for the postgres database in connection string
  #
  # You can run it individually with:
  #
  # ```
  # bundle exec gitlab-housekeeper -d \
  #   -k Keeps::OverdueFinalizeBackgroundMigration
  # ```
  class OverdueFinalizeBackgroundMigration < ::Gitlab::Housekeeper::Keep
    def each_change
      batched_background_migrations.each do |migration_yaml_file, migration|
        next unless before_cuttoff_milestone?(migration['milestone'])

        job_name = migration['migration_job_name']
        next if migration_finalized?(job_name)

        migration_record = fetch_migration_status(job_name)
        next unless migration_record

        last_migration_file = last_migration_for_job(job_name)
        next unless last_migration_file

        change = initialize_change(migration, migration_record, job_name, last_migration_file)

        queue_method_node = find_queue_method_node(last_migration_file)

        migration_name = truncate_migration_name("Finalize#{migration['migration_job_name']}")
        PostDeploymentMigration::PostDeploymentMigrationGenerator
          .source_root('generator_templates/post_deployment_migration/post_deployment_migration/')

        begin
          generator = ::PostDeploymentMigration::PostDeploymentMigrationGenerator.new([migration_name])
          migration_file = generator.invoke_all.first
          change.changed_files = [migration_file]

          add_ensure_call_to_migration(migration_file, queue_method_node, job_name, migration_record)
          ::Gitlab::Housekeeper::Shell.rubocop_autocorrect(migration_file)

          digest = Digest::SHA256.hexdigest(generator.migration_number)
          digest_file = Pathname.new('db').join('schema_migrations', generator.migration_number.to_s).to_s
          File.open(digest_file, 'w') { |f| f.write(digest) }

          add_finalized_by_to_yaml(migration_yaml_file, generator.migration_number)

          change.changed_files << digest_file
          change.changed_files << migration_yaml_file

          yield(change)
        rescue Rails::Generators::Error
          next
        end
      end
    end

    def initialize_change(migration, migration_record, job_name, last_migration_file)
      # Finalize the migration
      change = ::Gitlab::Housekeeper::Change.new
      change.title = "Finalize migration #{job_name}"

      change.identifiers = [self.class.name.demodulize, job_name]
      change.description = change_description(migration_record, job_name, last_migration_file)

      feature_category = migration['feature_category']

      change.labels = groups_helper.labels_for_feature_category(feature_category) + [
        'maintenance::removal'
      ]

      change.reviewers = groups_helper.pick_reviewer_for_feature_category(feature_category, change.identifiers)

      change
    end

    def change_description(migration_record, job_name, last_migration_file)
      # rubocop:disable Gitlab/DocumentationLinks/HardcodedUrl -- Not running inside rails application
      <<~MARKDOWN
      #{migration_code_not_present_message unless migration_code_present?(job_name)}
      This migration was finished at `#{migration_record.finished_at || migration_record.updated_at}`, you can confirm
      the status using our
      [batched background migration chatops commands](https://docs.gitlab.com/ee/development/database/batched_background_migrations.html#monitor-the-progress-and-status-of-a-batched-background-migration).
        To confirm it is finished you can run:

        ```
      /chatops run batched_background_migrations status #{migration_record.id}
      ```

      The last time this background migration was triggered was in [#{last_migration_file}](https://gitlab.com/gitlab-org/gitlab/-/blob/master/#{last_migration_file})

        You can read more about the process for finalizing batched background migrations in
      https://docs.gitlab.com/ee/development/database/batched_background_migrations.html .

        As part of our process we want to ensure all batched background migrations have had at least one
      [required stop](https://docs.gitlab.com/ee/development/database/required_stops.html)
      to process the migration. Therefore we can finalize any batched background migration that was added before the
      last required stop.
      MARKDOWN
      # rubocop:enable Gitlab/DocumentationLinks/HardcodedUrl
    end

    def truncate_migration_name(migration_name)
      # File names not allowed to exceed 100 chars due to Cop/FilenameLength so we truncate to 70 because there will be
      # underscores added.

      migration_name[0...70]
    end

    def add_finalized_by_to_yaml(yaml_file, migration_number)
      content = YAML.load_file(yaml_file)
      content['finalized_by'] = migration_number
      File.open(yaml_file, 'w') { |f| f.write(YAML.dump(content)) }
    end

    def last_migration_for_job(job_name)
      files = ::Gitlab::Housekeeper::Shell.execute('git', 'grep', '--name-only', "MIGRATION = .#{job_name}.")
        .each_line.map(&:chomp)

      result = files.select do |file|
        File.read(file).include?('queue_batched_background_migration')
      end.max

      raise "Could not find migration for #{job_name}" unless result.present?

      result
    rescue ::Gitlab::Housekeeper::Shell::Error
      # `git grep` returns an error status code if it finds no results
      nil
    end

    def add_ensure_call_to_migration(file, queue_method_node, job_name, migration_record)
      source = RuboCop::ProcessedSource.new(File.read(file), 3.1)
      ast = source.ast
      source_buffer = source.buffer
      rewriter = Parser::Source::TreeRewriter.new(source_buffer)

      up_method = ast.children[2].each_child_node(:def).find do |child|
        child.method_name == :up
      end

      table_name = queue_method_node.children[3]
      column_name = queue_method_node.children[4]
      job_arguments = queue_method_node.children[5..].select { |s| s.type != :hash } # All remaining non-keyword args

      gitlab_schema = migration_record.gitlab_schema

      added_content = <<~RUBY.strip
      disable_ddl_transaction!

      restrict_gitlab_migration gitlab_schema: :#{gitlab_schema}

        def up
          ensure_batched_background_migration_is_finished(
            job_class_name: '#{job_name}',
            table_name: #{table_name.source},
            column_name: #{column_name.source},
            job_arguments: [#{job_arguments.map(&:source).join(', ')}],
            finalize: true
          )
        end
      RUBY

      rewriter.replace(up_method.loc.expression, added_content)

      content = strip_comments(rewriter.process)

      File.write(file, content)
    end

    def strip_comments(code)
      result = []
      code.each_line.with_index do |line, index|
        result << line unless index > 0 && line.lstrip.start_with?('#')
      end
      result.join
    end

    def fetch_migration_status(job_name)
      result = postgres_ai.fetch_background_migration_status(job_name)

      return unless result.count == 1

      migration_model = ::Gitlab::Database::BackgroundMigration::BatchedMigration.new(result.first)

      migration_model if migration_model.finished?
    end

    def postgres_ai
      @postgres_ai ||= Keeps::Helpers::PostgresAi.new
    end

    def migration_finalized?(job_name)
      result = `git grep --name-only "#{job_name}"`.chomp
      result.each_line.select do |file|
        File.read(file.chomp).include?('ensure_batched_background_migration_is_finished')
      end.any?
    end

    def find_queue_method_node(file)
      source = RuboCop::ProcessedSource.new(File.read(file), 3.1)
      ast = source.ast

      up_method = ast.children[2].children.find do |child|
        child.def_type? && child.method_name == :up
      end

      up_method.each_descendant.find do |child|
        child && child.send_type? && child.method_name == :queue_batched_background_migration
      end
    end

    def before_cuttoff_milestone?(milestone)
      Gem::Version.new(milestone) <= Gem::Version.new(::Gitlab::Database.min_schema_gitlab_version)
    end

    def batched_background_migrations
      migrations = all_batched_background_migration_files.index_with do |f|
        YAML.load_file(f)
      end

      migrations.sort_by { |_f, migration| Gitlab::VersionInfo.parse_from_milestone(migration['milestone']) }
    end

    def all_batched_background_migration_files
      Dir.glob("db/docs/batched_background_migrations/*.yml")
    end

    def groups_helper
      @groups_helper ||= ::Keeps::Helpers::Groups.new
    end

    def migration_code_not_present_message
      <<~MARKDOWN
      ### Warning

      The migration code was **not found** in the codebase, the finalization cannot complete without it.

      Please re-add the background migration code to this merge request and start database testing pipeline
      MARKDOWN
    end

    def migration_code_present?(job_name)
      file_name = "#{job_name.underscore}.rb"
      migration_code_in_ce?(file_name) || migration_code_in_ee?(file_name)
    end

    def migration_code_in_ce?(file_name)
      File.exist?(
        Rails.root.join(*%w[lib gitlab background_migration]).join(file_name)
      )
    end

    def migration_code_in_ee?(file_name)
      File.exist?(
        Rails.root.join(*%w[ee lib ee gitlab background_migration]).join(file_name)
      )
    end
  end
end

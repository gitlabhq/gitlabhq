# frozen_string_literal: true

require 'rubocop'
require_relative 'helpers/ai_editor'
require_relative 'helpers/milestones'
require_relative 'prompts/remove_obsolete_migrations'

module Keeps
  # This is an implementation of a ::Gitlab::Housekeeper::Keep. This keep will not make any changes unless there are
  # Advanced search migrations to be marked as obsolete. This keep locates advanced search migrations that were added
  # before the cutoff milestone and adds a prepend to the bottom of the migration file which marks the migration as
  # obsolete in the code. It also updates the corresponding `ee/elastic/migrate/docs/` file with
  # a `marked_obsolete_in_milestone`. The cutoff milestone is defined as one milestone before the last required stop.
  # This is to prevent long running migrations from being marked as obsolete.
  #
  # You can run it manually with:
  #
  # ```
  # bundle exec gitlab-housekeeper -d -k Keeps::MarkOldAdvancedSearchMigrationsAsObsolete
  # ```
  class MarkOldAdvancedSearchMigrationsAsObsolete < ::Gitlab::Housekeeper::Keep
    MIGRATIONS_PATH = 'ee/elastic/migrate'
    MIGRATION_REGEXP = /\A([0-9]+)_([_a-z0-9]*)\.rb\z/
    MIGRATIONS_SPECS_PATH = 'ee/spec/elastic/migrate/'
    MIGRATION_DOCS_PATH = 'ee/elastic/docs'
    MAX_FILES_LIMIT = 50
    GREP_IGNORE = [
      'locale/',
      'db/structure.sql'
    ].freeze

    DEFAULT_GROUP_LABEL = 'group::global search'

    def initialize(...)
      @migrations_to_be_marked_obsolete = {}
      @group_team_maps = {}

      load_migrations_to_process

      super
    end

    def each_identified_change
      return if migrations_to_be_marked_obsolete.empty?

      migrations_to_be_marked_obsolete.each do |version, migration_data|
        migration_name = migration_data[:yaml_content]['name']
        migration_name_snake_case = migration_name.underscore
        change = ::Gitlab::Housekeeper::Change.new
        change.title = "Mark #{version} as obsolete"
        change.identifiers = ['mark_obsolete', version, migration_name]
        group_label = migration_data[:yaml_content]['group'] || DEFAULT_GROUP_LABEL
        change.labels = [
          'maintenance::refactor',
          group_label
        ]
        group_team_map = get_group_team_map(group_label)
        assignee = group_team_map.min_by { |_k, v| v }.first
        change.assignees = assignee
        group_team_map[assignee] += 1
        change.changelog_ee = true

        # rubocop:disable Gitlab/DocumentationLinks/HardcodedUrl -- Not running inside rails application
        change.description = <<~MARKDOWN
          This migration marks the #{version} #{migration_name} Advanced search migration as obsolete.

          ## Automated Changes

          This MR includes automated changes made by AI to remove references to the obsolete migration:

          - Migration file: Updated to prepend `::Search::Elastic::MigrationObsolete`
          - YAML documentation: Added `obsolete: true` and `marked_obsolete_in_milestone`
          - Spec file: Updated to use `it_behaves_like 'a deprecated Advanced Search migration'`
          - **Code references**: AI attempted to find and remove/simplify references to this migration throughout the codebase

          ## Critical Pattern: `migration_has_finished?` Checks

          When a migration is obsolete, `::Elastic::DataMigrationService.migration_has_finished?(:#{migration_name_snake_case})` always returns `true`.

          The AI has attempted to simplify conditionals and remove dead code branches:
          - `if migration_has_finished?(:#{migration_name_snake_case})` - kept the if branch, removed else branch
          - `unless migration_has_finished?(:#{migration_name_snake_case})` - removed entire block (never executes)
          - Combined conditions like `feature_flag && migration_has_finished?(:#{migration_name_snake_case})` - simplified to just `feature_flag`
          - Test stubs returning `false` - removed tests for scenarios that can no longer occur

          ## Review Checklist

          - [ ] Verify all `migration_has_finished?(:#{migration_name_snake_case})` checks have been removed or simplified
          - [ ] Confirm that simplified logic maintains the same behavior (the "if finished" branch is now always taken)
          - [ ] Check for any remaining references to `#{migration_name}` (class name) or `#{migration_name_snake_case}` (snake_case)
          - [ ] Review test coverage to ensure meaningful tests remain after removing obsolete scenarios
          - [ ] Verify CI passes with all changes

          ## Search for Remaining References

          - [Search for class name: `#{migration_name}`](https://gitlab.com/search?project_id=278964&scope=blobs&search=#{migration_name}&regex=false)
          - [Search for snake_case name: `#{migration_name_snake_case}`](https://gitlab.com/search?project_id=278964&scope=blobs&search=#{migration_name_snake_case}&regex=false)
          - [Search for migration check: `migration_has_finished?(:#{migration_name_snake_case})`](https://gitlab.com/search?project_id=278964&scope=blobs&search=migration_has_finished%3F%28%3A#{migration_name_snake_case}%29&regex=false)

          ## Additional Notes

          At the moment, the `gitlab-housekeeper` AI integration is not always capable of removing all references, so
          you must check the diff and pipeline failures to confirm if there are any issues.
          It is the responsibility of the assignee to push those changes to this branch if needed.

          [Read more](https://docs.gitlab.com/ee/development/search/advanced_search_migration_styleguide.html#cleaning-up-advanced-search-migrations)
          about the process for marking Advanced search migrations as obsolete.

          All Advanced search migrations must have had at least one
          [required stop](https : // docs.gitlab.com / ee / development / database / required_stops.html)
          to process the migration. Therefore we mark any Advanced search migrations added before the
          last required stop as obsolete.
        MARKDOWN
        # rubocop:enable Gitlab/DocumentationLinks/HardcodedUrl

        change.context = { version: version, migration_data: migration_data }

        yield(change)
      end

      nil
    end

    def make_change!(change)
      version = change.context[:version]
      migration_data = change.context[:migration_data]

      change.changed_files = []
      add_obsolete_to_yaml(migration_data[:yaml_filename], migration_data[:yaml_content])
      change.changed_files << migration_data[:yaml_filename]

      add_obsolete_to_migration(migration_data[:file])
      change.changed_files << migration_data[:file]

      if File.exist?(migration_data[:spec_file])
        add_obsolete_to_migration_spec(version, migration_data[:spec_file], migration_data[:yaml_content]['name'])
        change.changed_files << migration_data[:spec_file]
      end

      # Attempt to use AI to clean up references to the obsolete migration
      ai_applied = ai_patch(migration_data, change)

      @logger.puts "Warning: AI patching was not fully successful, but manual changes were applied." unless ai_applied

      # If AI made changes, we should run CI to verify them
      change.push_options.ci_skip = true unless change.changed_files.size > 3

      change
    end

    def ai_patch(migration_data, change)
      migration_name = migration_data[:yaml_content]['name']
      migration_version = migration_data[:yaml_content]['version']
      migration_snake_case = migration_name.underscore

      failed_files = []
      files_to_patch = files_mentioning_migration(migration_name, migration_version)

      # Exclude the migration file itself and its spec file
      files_to_patch.reject! do |file|
        file == migration_data[:file] ||
          file == migration_data[:spec_file] ||
          file == migration_data[:yaml_filename]
      end

      if files_to_patch.size > MAX_FILES_LIMIT
        @logger.puts "More than #{MAX_FILES_LIMIT} files are mentioning migration #{migration_name}, Skipping."
        return false
      end

      if files_to_patch.empty?
        @logger.puts "No additional files found mentioning migration #{migration_name}."
        return true
      end

      @logger.puts "Found #{files_to_patch.size} files mentioning migration #{migration_name}."

      files_to_patch.each do |file|
        user_message = remove_obsolete_migration_prompts.fetch(migration_name, migration_snake_case, file)

        unless user_message
          @logger.puts "#{migration_name}: No prompt generated for #{file}, skipping"
          next
        end

        applied = ai_helper.ask_for_and_apply_patch(user_message, file)

        unless applied
          @logger.puts "#{migration_name}: Failed to apply AI patch for #{file}, skipping"
          failed_files << file
          next
        end

        # Run rubocop autocorrect on Ruby files
        unless file.end_with?('.md')
          begin
            ::Gitlab::Housekeeper::Shell.rubocop_autocorrect(file)
          rescue ::Gitlab::Housekeeper::Shell::Error => e
            @logger.puts "#{migration_name}: Rubocop error for #{file}, but continuing: #{e.message}"
          end
        end

        change.changed_files << file
      end

      if failed_files.any?
        @logger.puts "Failed to apply AI patches to #{failed_files.size} files"
        @logger.puts "Failed files: #{failed_files.join(', ')}"
      end

      failed_files.empty?
    end

    private

    attr_reader :migrations_to_be_marked_obsolete, :group_team_maps

    def load_migrations_to_process
      each_advanced_search_migration do |migration_filename, spec_filename, yaml_filename, yaml_content|
        version = yaml_content['version']
        next unless before_cutoff_milestone?(yaml_content['milestone'])
        next if yaml_content['obsolete']
        next unless before_cutoff_milestone?(yaml_content['milestone'])

        migrations_to_be_marked_obsolete[version] =
          {
            file: migration_filename,
            spec_file: spec_filename,
            yaml_filename: yaml_filename,
            yaml_content: yaml_content
          }
      end
    end

    def get_migration_versions_from_codebase
      migration_files = Dir[File.join(MIGRATIONS_PATH, '**', '[0-9]*_*.rb')]
      migration_versions_hash = {}
      migration_files.each do |migration_file|
        version, filename = File.basename(migration_file).scan(MIGRATION_REGEXP).first
        migration_versions_hash[version] = { version: version, filename: filename }
      end
      migration_versions_hash
    end

    def before_cutoff_milestone?(milestone)
      Gem::Version.new(milestone) < Gem::Version.new(cutoff_milestone.to_s)
    end

    def each_advanced_search_migration
      all_advanced_search_migration_files.map do |f|
        version, filename = File.basename(f).scan(MIGRATION_REGEXP).first
        yaml_file = "#{MIGRATION_DOCS_PATH}/#{version}_#{filename}.yml"
        spec_file = "#{MIGRATIONS_SPECS_PATH}/#{version}_#{filename}_spec.rb"

        yield(f, spec_file, yaml_file, YAML.load_file(yaml_file))
      end
    end

    def all_advanced_search_migration_files
      Dir.glob("#{MIGRATIONS_PATH}/*.rb")
    end

    def add_obsolete_to_yaml(file, content)
      content['obsolete'] = true
      content['marked_obsolete_in_milestone'] = migration_marked_as_obsolete_milestone.to_s
      File.open(file, 'w') { |f| f.write(YAML.dump(content)) }
    end

    def add_obsolete_to_migration(file)
      source = RuboCop::ProcessedSource.new(File.read(file), RuboCop::ConfigStore.new.for_file('.').target_ruby_version)
      ast = source.ast
      klass_name = ast.children[0].source

      File.open(file, 'a') { |f| f.write("\n#{klass_name}.prepend ::Search::Elastic::MigrationObsolete\n") }
    end

    def add_obsolete_to_migration_spec(version, file, name)
      source = RuboCop::ProcessedSource.new(File.read(file), RuboCop::ConfigStore.new.for_file('.').target_ruby_version)
      rewriter = Parser::Source::TreeRewriter.new(source.buffer)
      describe_block = source.ast.each_node(:block).first
      content = <<~RUBY.strip
        RSpec.describe #{name}, feature_category: :global_search do
          it_behaves_like 'a deprecated Advanced Search migration', #{version}
        end
      RUBY

      rewriter.replace(describe_block.loc.expression, content)
      process = rewriter.process.lstrip.gsub(/\n{3,}/, "\n\n")

      File.write(file, process)
    end

    def migration_marked_as_obsolete_milestone
      @migration_marked_as_obsolete_milestone ||= read_milestone
    end

    def read_milestone
      milestone = File.read('VERSION')
      milestone.gsub(/^(\d+\.\d+).*$/, '\1').chomp
    end

    def get_group_team_map(group_label)
      group = groups_helper.group_for_group_label(group_label)
      @group_team_maps[group_label] ||= groups_helper.available_reviewers_for_group(group,
        reviewer_types: ['backend_engineers']).index_with(0)
    end

    def groups_helper
      ::Keeps::Helpers::Groups.instance
    end

    def cutoff_milestone
      @cutoff_milestone ||= calculate_cutoff_milestone
    end

    def calculate_cutoff_milestone
      # Only mark migrations added in the milestone before the last required stop as obsolete
      last_required_stop = Gitlab::Database.min_schema_gitlab_version

      if last_required_stop.minor > 0
        Gitlab::VersionInfo.new(last_required_stop.major, last_required_stop.minor - 1, 0)
      else
        Gitlab::VersionInfo.new(last_required_stop.major - 1, 11, 0)
      end
    end

    def ai_helper
      ::Keeps::Helpers::AiEditor.new
    end

    def remove_obsolete_migration_prompts
      @remove_obsolete_migration_prompts ||= ::Keeps::Prompts::RemoveObsoleteMigrations.new(@logger)
    end

    def git_patterns(migration_name, migration_version)
      migration_snake_case = migration_name.underscore
      [
        migration_name,
        migration_snake_case,
        "migration_has_finished?(:#{migration_snake_case})",
        migration_version.to_s
      ]
    end

    def files_mentioning_migration(migration_name, migration_version)
      all_files = []

      git_patterns(migration_name, migration_version).each do |pattern|
        result = find_files_with_pattern(pattern)
        all_files += result if result.any?
      end

      all_files.uniq
    end

    def find_files_with_pattern(pattern)
      result = execute_grep(pattern)

      return [] if result.blank?

      result.split("\n")
    rescue ::Gitlab::Housekeeper::Shell::Error
      @logger.puts "No files found for pattern: #{pattern}" if @logger
      []
    end

    def execute_grep(pattern)
      ::Gitlab::Housekeeper::Shell.execute(
        'git',
        'grep',
        '--name-only',
        pattern,
        '--',
        *(GREP_IGNORE.map { |path| ":^#{path}" })
      )
    rescue ::Gitlab::Housekeeper::Shell::Error
      # git grep returns error status if nothing is found
      ""
    end
  end
end

# frozen_string_literal: true

require_relative 'helpers/file_helper'
require_relative '../spec/support/helpers/database/duplicate_indexes'
require_relative '../lib/generators/post_deployment_migration/post_deployment_migration_generator'

module Keeps
  # This is an implementation of a ::Gitlab::Housekeeper::Keep. This keep will look for duplicated indexes
  # and it will generate the corresponding files to have the index dropped. For each index to be dropped, the Keep will
  # generate a new migration and its schema migration file. It also updates the `db/schema.sql` for each migration file.
  #
  # This keep uses the test databases to generate a updated version of the schema. Each time the keep is invoked it will
  # recreate the `gitlabhq_test` and `gitlabhq_test_ci` databases.
  #
  # You can run it individually with:
  #
  # ```
  # bundle exec gitlab-housekeeper -d \
  #   -k Keeps::RemoveDuplicatedIndexes
  # ```
  class RemoveDuplicatedIndexes < ::Gitlab::Housekeeper::Keep
    MIGRATION_TEMPLATE = 'generator_templates/active_record/migration/'
    FALLBACK_REVIEWER_FEATURE_CATEGORY = 'database'
    DUPLICATED_INDEXES_FILE = 'spec/support/helpers/database/duplicate_indexes.yml'

    def initialize(...)
      ::Gitlab::Application.load_tasks
      ::PostDeploymentMigration::PostDeploymentMigrationGenerator.source_root(MIGRATION_TEMPLATE)

      @indexes_to_drop = {}

      reset_db
      migrate
      load_indexes_to_drop

      super
    end

    def each_change
      indexes_to_drop.each do |table_name, indexes|
        change = build_change(table_name, indexes)
        change.changed_files = []

        indexes.each do |index_to_drop, _|
          migration_file, migration_number = generate_migration_file(table_name, index_to_drop)
          update_duplicated_indexes_file(table_name)

          change.changed_files << migration_file
          change.changed_files << Pathname.new('db').join('schema_migrations', migration_number).to_s
          change.changed_files << DUPLICATED_INDEXES_FILE
        end

        migrate

        change.changed_files << Pathname.new('db').join('structure.sql').to_s

        yield(change)

        reset_db
      end
    end

    private

    attr_reader :indexes_to_drop

    def load_indexes_to_drop
      establish_test_db_connection do |connection|
        connection.tables.sort.each do |table|
          # Skip partitioned tables for now
          next if Gitlab::Database::PostgresPartition.partition_exists?(table)

          result = process_result(Database::DuplicateIndexes.new(table, connection.indexes(table)).duplicate_indexes)

          next if result.empty?

          indexes_to_drop[table] = result
        end
      end
    end

    def build_change(table_name, indexes)
      change = ::Gitlab::Housekeeper::Change.new
      change.title = "Remove duplicated index from #{table_name}".truncate(70, omission: '')
      change.identifiers = [self.class.name.demodulize, table_name]
      change.labels = labels(table_name)
      change.reviewers = pick_reviewers(table_name, change.identifiers).uniq

      removes_section = indexes.map do |index_to_drop, matching_indexes|
        matching_indexes_table = matching_indexes.map do |idx|
          <<-MARKDOWN.strip
          | `#{idx.name}` | #{idx.columns.map { |col| "`#{col[:name]} #{col[:order]}`" }.join(', ')} |
          MARKDOWN
        end

        <<~MARKDOWN.strip
          Drop `#{index_to_drop.name}` as it's already covered by:
          | Index | Columns |
          | ----- | ------ |
          #{matching_indexes_table.join("\n")}
        MARKDOWN
      end

      change.description = <<~MARKDOWN.chomp
        ## What does this MR do and why?

        Remove duplicated index from `#{table_name}` table.

        ### It removes:

        #{removes_section.join("\n")}

        It is possible that this MR will still need some changes to drop the index from the database.
        Currently, the `gitlab-housekeeper` is not always capable of removing all references, so you must check the diff and pipeline failures to confirm if there are any issues.
        Ensure that the index exists in the production database by checking Joe Bot trough https://console.postgres.ai/gitlab.
        If the index was already removed or if the index it's being removed in another merge request, consider closing this merge request.
      MARKDOWN

      change
    end

    def process_result(duplicated_indexes)
      duplicates_map = Hash.new { |h, k| h[k] = [] }

      duplicated_indexes.each do |index, duplicates|
        duplicates.each do |duplicate|
          duplicates_map[duplicate] << index
        end
      end

      duplicates_map
    end

    def generate_migration_file(table_name, index_to_drop)
      migration_name = "drop_#{index_to_drop.name}".truncate(100, omission: '')
      generator = ::PostDeploymentMigration::PostDeploymentMigrationGenerator.new([migration_name])
      migration_content = <<~RUBY.strip
        disable_ddl_transaction!

          TABLE_NAME = :#{table_name}
          INDEX_NAME = :#{index_to_drop.name}
          COLUMN_NAMES = #{index_to_drop.columns.map { |col| col[:name].to_sym }}

          def up
            remove_concurrent_index_by_name(TABLE_NAME, INDEX_NAME)
          end

          def down
            add_concurrent_index(TABLE_NAME, COLUMN_NAMES, name: INDEX_NAME)
          end
      RUBY

      migration_file = generator.invoke_all.first
      file_helper = ::Keeps::Helpers::FileHelper.new(migration_file)
      file_helper.replace_method_content(:change, migration_content, strip_comments_from_file: true)

      ::Gitlab::Housekeeper::Shell.execute('rubocop', '-a', migration_file)

      [migration_file, generator.migration_number]
    end

    def update_duplicated_indexes_file(table_name)
      file_path = Rails.root.join(DUPLICATED_INDEXES_FILE)
      file = YAML.load_file(file_path)
      file.delete(table_name)

      File.write(DUPLICATED_INDEXES_FILE, file.to_yaml)
    end

    def pick_reviewers(table_name, identifiers)
      table_info = Gitlab::Database::Dictionary.entries.find_by_table_name(table_name)

      table_info.feature_categories.map do |feature_category|
        groups_helper.pick_reviewer_for_feature_category(feature_category, identifiers,
          fallback_feature_category: FALLBACK_REVIEWER_FEATURE_CATEGORY)
      end
    end

    def labels(table_name)
      table_info = Gitlab::Database::Dictionary.entries.find_by_table_name(table_name)

      group_labels = table_info.feature_categories.flat_map do |feature_category|
        groups_helper.labels_for_feature_category(feature_category)
      end

      group_labels + %w[maintenance::scalability type::maintenance Category:Database]
    end

    def establish_test_db_connection
      # rubocop:disable Database/EstablishConnection -- We should use test database only
      yield ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations.find_db_config('test')).connection
      # rubocop:enable Database/EstablishConnection
    end

    def reset_db
      ApplicationRecord.clear_all_connections!
      ::Gitlab::Housekeeper::Shell.execute('rails', 'db:reset', env: { 'RAILS_ENV' => 'test' })
    end

    def migrate
      ::Gitlab::Housekeeper::Shell.execute('rails', 'db:migrate', env: { 'RAILS_ENV' => 'test' })
    end

    def groups_helper
      @groups_helper ||= ::Keeps::Helpers::Groups.new
    end
  end
end

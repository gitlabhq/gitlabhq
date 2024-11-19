# frozen_string_literal: true

require_relative 'helpers/file_helper'
require_relative 'helpers/milestones'
require_relative '../lib/generators/post_deployment_migration/post_deployment_migration_generator'

module Keeps
  # This is an implementation of ::Gitlab::Housekeeper::Keep.
  # This initializes the conversion of bigint columns for a given table.
  #
  # You can run it individually with:
  #
  # ```
  # bundle exec gitlab-housekeeper -d -k Keeps::InitializeBigIntConversion
  # ```
  class InitializeBigIntConversion < ::Gitlab::Housekeeper::Keep
    INTEGER_COLUMNS_FILE = 'db/integer_ids_not_yet_initialized_to_bigint.yml'
    MIGRATION_TEMPLATE = 'generator_templates/active_record/migration/'
    FALLBACK_REVIEWER_FEATURE_CATEGORY = 'database'
    CLASS_WITH_NAMESPACE = /class\s+([A-Z][A-Za-z0-9]*(?:::[A-Z][A-Za-z0-9]*)+)\s*(?:<\s*[A-Z][A-Za-z0-9:]*\s*)?$/
    CLASS_WITHOUT_NAMESPACE = /class\s+([A-Z][A-Za-z0-9]*)\s*(?:<\s*[A-Z][A-Za-z0-9:]*\s*)?$/

    TABLE_INT_IDS_YAML_FILE_COMMENT = <<~MESSAGE
      # -- DON'T MANUALLY EDIT --
      # Contains the list of integer IDs which were converted to bigint for new installations in
      # https://gitlab.com/gitlab-org/gitlab/-/issues/438124, but they are still integers for existing instances.
      # On initialize_conversion_of_integer_to_bigint those integer IDs will be removed automatically from here.
    MESSAGE

    def initialize(...)
      ::PostDeploymentMigration::PostDeploymentMigrationGenerator.source_root(MIGRATION_TEMPLATE)

      reset_db
      migrate

      super
    end

    def each_change
      integer_columns_to_migrate.each do |table_name, columns|
        change = build_change(table_name, columns)
        change.changed_files = []
        migration_file_1, migration_number_1 = generate_initialization_migration_file(table_name, columns)
        migration_file_2, migration_number_2 = generate_backfill_migration_file(table_name, columns)

        change.changed_files << migration_file_1
        change.changed_files << migration_file_2
        change.changed_files << Pathname.new('db').join('schema_migrations', migration_number_1).to_s
        change.changed_files << Pathname.new('db').join('schema_migrations', migration_number_2).to_s

        file_path = update_model(table_name, columns)
        update_integer_columns_file(table_name)

        migrate
        change.changed_files << Pathname.new('db').join('structure.sql').to_s
        change.changed_files << file_path
        change.changed_files << INTEGER_COLUMNS_FILE

        yield(change)

        reset_db
      end
    end

    private

    def integer_columns_to_migrate
      YAML.safe_load_file(INTEGER_COLUMNS_FILE)
    end

    def build_change(table_name, columns)
      change = ::Gitlab::Housekeeper::Change.new
      change.title = "Prepare conversion of #{table_name} to bigint".truncate(70, omission: '')
      change.identifiers = [self.class.name.demodulize, table_name]
      change.changelog_type = 'added'
      change.labels = labels(table_name)
      change.reviewers = pick_reviewers(table_name, change.identifiers).uniq

      change.description = <<~MARKDOWN
      Prepares conversion of `#{table_name}` to bigint for `#{columns.join(', ')}`

      You can read more about the process for preparing bigint conversion in
      https://docs.gitlab.com/ee/development/database/avoiding_downtime_in_migrations.html#migrating-integer-primary-keys-to-bigint.

      As part of our process we want to ensure all ID columns are bigint to avoid the risk of overflowing while we continue our growth.

      See https://gitlab.com/gitlab-org/gitlab/-/issues/465805+

      Verify this MR as it was automatically created by `gitlab-housekeeper`.

      Ensure that those columns are not being converted yet in the production database by checking Joe Bot through https://console.postgres.ai/gitlab.
      If the columns were already converted in another merge request, consider closing this merge request
      MARKDOWN

      change
    end

    def labels(table_name)
      table_info = Gitlab::Database::Dictionary.entries.find_by_table_name(table_name)

      group_labels = table_info.feature_categories.flat_map do |feature_category|
        groups_helper.labels_for_feature_category(feature_category)
      end

      group_labels << 'maintenance::scalability'
    end

    def pick_reviewers(table_name, identifiers)
      table_info = Gitlab::Database::Dictionary.entries.find_by_table_name(table_name)

      table_info.feature_categories.map do |feature_category|
        groups_helper.pick_reviewer_for_feature_category(feature_category, identifiers,
          fallback_feature_category: FALLBACK_REVIEWER_FEATURE_CATEGORY)
      end
    end

    def generate_initialization_migration_file(table_name, columns)
      migration_name = "initialize_conversion_of_#{table_name}_to_bigint".truncate(100, omission: '')
      generator = ::PostDeploymentMigration::PostDeploymentMigrationGenerator.new([migration_name])

      migration_content = <<~RUBY.strip
        disable_ddl_transaction!

        TABLE_NAME = :#{table_name}
        COLUMNS = %i[#{columns.join(' ')}]

        def up
          initialize_conversion_of_integer_to_bigint(TABLE_NAME, COLUMNS, primary_key: :#{primary_key(table_name)})
        end

        def down
          revert_initialize_conversion_of_integer_to_bigint(TABLE_NAME, COLUMNS)
        end
      RUBY

      migration_file = generator.invoke_all.first
      file_helper = ::Keeps::Helpers::FileHelper.new(migration_file)
      file_helper.replace_method_content(:change, migration_content, strip_comments_from_file: true)

      ::Gitlab::Housekeeper::Shell.execute('rubocop', '-a', migration_file)

      [migration_file, generator.migration_number]
    end

    def generate_backfill_migration_file(table_name, columns)
      migration_name = "backfill_#{table_name}_for_bigint_conversion".truncate(100, omission: '')
      generator = ::PostDeploymentMigration::PostDeploymentMigrationGenerator.new([migration_name])
      gitlab_schema = Gitlab::Database::Dictionary.entries.find_by_table_name(table_name).gitlab_schema

      migration_content = <<~RUBY.strip
        disable_ddl_transaction!
        restrict_gitlab_migration gitlab_schema: :#{gitlab_schema}

        TABLE_NAME = :#{table_name}
        COLUMNS = %i[#{columns.join(' ')}]

        def up
          backfill_conversion_of_integer_to_bigint(TABLE_NAME, COLUMNS, primary_key: :#{primary_key(table_name)})
        end

        def down
          revert_backfill_conversion_of_integer_to_bigint(TABLE_NAME, COLUMNS)
        end
      RUBY

      migration_file = generator.invoke_all.first
      file_helper = ::Keeps::Helpers::FileHelper.new(migration_file)
      file_helper.replace_method_content(:change, migration_content, strip_comments_from_file: true)

      ::Gitlab::Housekeeper::Shell.execute('rubocop', '-a', migration_file)

      [migration_file, generator.migration_number]
    end

    def model_path(table_name)
      model = Gitlab::Database::Dictionary.entries.find_by_table_name(table_name).classes.first
      nested_model = model.underscore
      file_path = Rails.root.join('app', 'models', "#{nested_model}.rb").to_s

      if File.exist?(file_path)
        file_path
      else
        Rails.root.join('ee', 'app', 'models', "#{nested_model}.rb").to_s
      end
    end

    def update_model(table_name, columns)
      class_name = Gitlab::Database::Dictionary.entries.find_by_table_name(table_name).classes.first.split("::").last
      file_path = model_path(table_name)

      ignore_columns = columns.map do |column|
        "ignore_column :#{column}_convert_to_bigint, remove_with: '#{n_3_milestone.version}', " \
          "remove_after: '#{n_2_milestone.date}'"
      end

      new_content = <<~RUBY
        #{ignore_columns.join("\n")}
      RUBY

      insert_after_class_definition(file_path, class_name, new_content)
      ::Gitlab::Housekeeper::Shell.execute('rubocop', '-a', file_path)

      file_path
    end

    def insert_after_class_definition(file_path, class_name, new_content)
      content = File.read(file_path)
      pattern = class_name.include?('::') ? CLASS_WITH_NAMESPACE : CLASS_WITHOUT_NAMESPACE

      matches = content.scan(pattern)
      return unless matches.flatten.include?(class_name)

      updated_content = content.gsub(pattern) do |match|
        if ::Regexp.last_match(1) == class_name
          "#{match}\n#{new_content}\n"
        else
          match
        end
      end

      File.write(file_path, updated_content)
    end

    def update_integer_columns_file(table_name)
      file_path = Rails.root.join(INTEGER_COLUMNS_FILE)
      data = YAML.safe_load_file(file_path)
      data.delete(table_name)

      File.open(INTEGER_COLUMNS_FILE, 'w') do |f|
        f.write(TABLE_INT_IDS_YAML_FILE_COMMENT)
        f.write(data.to_yaml)
      end
    end

    def migrate
      ::Gitlab::Housekeeper::Shell.execute('rails', 'db:migrate', env: { 'RAILS_ENV' => 'test' })
    end

    def reset_db
      ApplicationRecord.clear_all_connections!
      ::Gitlab::Housekeeper::Shell.execute('rails', 'db:reset', env: { 'RAILS_ENV' => 'test' })
    end

    def n_2_milestone
      milestones_helper.upcoming_milestones[2]
    end

    def n_3_milestone
      milestones_helper.upcoming_milestones[3]
    end

    def groups_helper
      @groups_helper ||= ::Keeps::Helpers::Groups.new
    end

    def milestones_helper
      @milestones_helper ||= ::Keeps::Helpers::Milestones.new
    end

    def primary_key(table_name)
      Gitlab::Database::Dictionary.entries.find_by_table_name(table_name).classes.first.constantize.primary_key
    end
  end
end

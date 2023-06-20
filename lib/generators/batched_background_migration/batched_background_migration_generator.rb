# frozen_string_literal: true

require 'rails/generators/active_record'

module BatchedBackgroundMigration
  class BatchedBackgroundMigrationGenerator < ActiveRecord::Generators::Base
    source_root File.expand_path('templates', __dir__)

    class_option :table_name, type: :string, required: true, desc: "Table from which records we will be batching"
    class_option :column_name, type: :string, required: true, desc: "Column to use for batching", default: :id
    class_option :feature_category, type: :string, required: true,
      desc: "Feature category to which this batched background migration belongs to"
    class_option :ee_only, type: :boolean, desc: "Generate files for EE-only batched background migration",
      default: false

    def validate!
      raise ArgumentError, "table_name is required" unless table_name.present?
      raise ArgumentError, "column_name is required" unless column_name.present?
      raise ArgumentError, "feature_category is required" unless feature_category.present?
    end

    def create_post_migration_and_specs
      migration_template(
        "queue_batched_background_migration.template",
        File.join(db_migrate_path, "queue_#{file_name}.rb")
      )

      template(
        "queue_batched_background_migration_spec.template",
        File.join("spec/migrations/#{migration_number}_queue_#{file_name}_spec.rb")
      )
    end

    def create_batched_background_migration_class_and_specs
      if ee_only?
        template(
          "ee_batched_background_migration_job.template",
          File.join("ee/lib/ee/gitlab/background_migration/#{file_name}.rb")
        )

        template(
          "foss_batched_background_migration_job.template",
          File.join("lib/gitlab/background_migration/#{file_name}.rb")
        )

        template(
          "batched_background_migration_job_spec.template",
          File.join("ee/spec/lib/ee/gitlab/background_migration/#{file_name}_spec.rb")
        )
      else
        template(
          "batched_background_migration_job.template",
          File.join("lib/gitlab/background_migration/#{file_name}.rb")
        )

        template(
          "batched_background_migration_job_spec.template",
          File.join("spec/lib/gitlab/background_migration/#{file_name}_spec.rb")
        )
      end
    end

    def create_dictionary_file
      template(
        "batched_background_migration_dictionary.template",
        File.join("db/docs/batched_background_migrations/#{file_name}.yml")
      )
    end

    def db_migrate_path
      super.sub("migrate", "post_migrate")
    end

    private

    def table_name
      options[:table_name]
    end

    def column_name
      options[:column_name]
    end

    def feature_category
      options[:feature_category]
    end

    def ee_only?
      options[:ee_only]
    end

    def current_milestone
      version = Gem::Version.new(File.read('VERSION'))
      version.release.segments.first(2).join('.')
    end
  end
end

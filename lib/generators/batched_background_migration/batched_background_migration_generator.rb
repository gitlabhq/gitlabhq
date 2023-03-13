# frozen_string_literal: true

require 'rails/generators/active_record'

module BatchedBackgroundMigration
  class BatchedBackgroundMigrationGenerator < ActiveRecord::Generators::Base
    source_root File.expand_path('templates', __dir__)

    class_option :table_name
    class_option :column_name
    class_option :feature_category

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
      template(
        "batched_background_migration_job.template",
        File.join("lib/gitlab/background_migration/#{file_name}.rb")
      )

      template(
        "batched_background_migration_job_spec.template",
        File.join("spec/lib/gitlab/background_migration/#{file_name}_spec.rb")
      )
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

    def current_milestone
      version = Gem::Version.new(File.read('VERSION'))
      version.release.segments.first(2).join('.')
    end
  end
end

# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/active_record'
require 'rails/generators/active_record/migration/migration_generator'

module Gitlab
  module ClickHouse
    class MigrationGenerator < ActiveRecord::Generators::MigrationGenerator
      source_root File.expand_path('templates', __dir__)

      desc <<~DESC
        Creates a ClickHouse database migration

        Example:
          rails generate gitlab:click_house:migration CreateProjects

        This will create:
          db/clickhouse/migrate/main/TIMESTAMP_create_projects.rb
      DESC

      def db_migrate_path
        'db/click_house/migrate/main'
      end

      # Override create_migration_file to ensure custom template is used
      def create_migration_file
        set_local_assigns!
        validate_file_name!
        migration_template "migration.rb.template", File.join(db_migrate_path, "#{file_name}.rb")
      end
    end
  end
end

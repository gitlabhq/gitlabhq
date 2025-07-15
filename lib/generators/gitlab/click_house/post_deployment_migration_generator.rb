# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/active_record'
require 'rails/generators/active_record/migration/migration_generator'

module Gitlab
  module ClickHouse
    class PostDeploymentMigrationGenerator < MigrationGenerator
      source_root File.expand_path('templates', __dir__)

      def db_migrate_path
        super.sub("migrate", "post_migrate")
      end
    end
  end
end

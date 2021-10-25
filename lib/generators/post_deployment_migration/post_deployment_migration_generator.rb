# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/active_record'
require 'rails/generators/active_record/migration/migration_generator'

module PostDeploymentMigration
  class PostDeploymentMigrationGenerator < ActiveRecord::Generators::MigrationGenerator
    def db_migrate_path
      super.sub("migrate", "post_migrate")
    end
  end
end

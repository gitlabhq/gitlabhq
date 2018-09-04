require 'rails/generators'
require 'rails/generators/active_record'
require 'rails/generators/active_record/migration/migration_generator'

class GeoMigrationGenerator < ActiveRecord::Generators::MigrationGenerator
  source_root File.join(Rails.root, 'generator_templates/active_record/migration')

  def create_migration_file
    set_local_assigns!
    validate_file_name!
    migration_template @migration_template, "ee/db/geo/migrate/#{file_name}.rb"
  end
end

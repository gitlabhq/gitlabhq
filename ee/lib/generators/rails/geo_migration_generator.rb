require 'rails/generators'
require 'rails/generators/active_record'
require 'rails/generators/active_record/migration/migration_generator'

# TODO: this can be removed once we verify that this works as intended if we're
# on Rails 5 since we use private Rails APIs.
raise "Vendored ActiveRecord 5 code! Delete #{__FILE__}!" if ActiveRecord::VERSION::MAJOR >= 5

class GeoMigrationGenerator < ActiveRecord::Generators::MigrationGenerator
  source_root File.join(File.dirname(ActiveRecord::Generators::MigrationGenerator.instance_method(:create_migration_file).source_location.first), 'templates')

  def create_migration_file
    set_local_assigns!
    validate_file_name!
    migration_template @migration_template, "ee/db/geo/migrate/#{file_name}.rb"
  end
end

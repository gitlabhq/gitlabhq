# frozen_string_literal: true

require 'rails/generators'
require 'rails/generators/active_record/model/model_generator'

module Model
  class ModelGenerator < ActiveRecord::Generators::ModelGenerator
    source_root File.expand_path('../../../generator_templates/active_record/migration/', __dir__)

    def create_migration_file
      return if skip_migration_creation?

      if options[:indexes] == false
        attributes.each { |a| a.attr_options.delete(:index) if a.reference? && !a.has_index? }
      end

      migration_template "create_table_migration.rb", File.join(db_migrate_path, "create_#{table_name}.rb")
    end

    def create_database_dictionary
      template "database_dictionary.yml", Rails.root.join("db", "docs", "#{table_name}.yml").to_s
    end

    # Override to find templates from superclass as well
    def source_paths
      super + [self.class.superclass.default_source_root]
    end
  end
end

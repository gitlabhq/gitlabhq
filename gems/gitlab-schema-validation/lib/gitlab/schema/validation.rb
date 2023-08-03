# frozen_string_literal: true

require 'pg_query'
require 'diffy'

require_relative 'validation/version'
require_relative 'validation/inconsistency'
require_relative 'validation/pg_types'

require_relative 'validation/validators/base'

require_relative 'validation/validators/different_definition_indexes'
require_relative 'validation/validators/extra_indexes'
require_relative 'validation/validators/missing_indexes'

require_relative 'validation/validators/extra_table_columns'
require_relative 'validation/validators/missing_table_columns'

require_relative 'validation/validators/different_definition_foreign_keys'
require_relative 'validation/validators/extra_foreign_keys'
require_relative 'validation/validators/missing_foreign_keys'

require_relative 'validation/validators/different_definition_tables'
require_relative 'validation/validators/extra_tables'
require_relative 'validation/validators/missing_tables'

require_relative 'validation/validators/different_definition_triggers'
require_relative 'validation/validators/extra_triggers'
require_relative 'validation/validators/missing_triggers'

require_relative 'validation/sources/connection_adapters/base'
require_relative 'validation/sources/connection_adapters/active_record_adapter'
require_relative 'validation/sources/connection_adapters/pg_adapter'
require_relative 'validation/sources/structure_sql'
require_relative 'validation/sources/database'
require_relative 'validation/sources/connection'

require_relative 'validation/schema_objects/base'
require_relative 'validation/schema_objects/column'
require_relative 'validation/schema_objects/index'
require_relative 'validation/schema_objects/table'
require_relative 'validation/schema_objects/trigger'
require_relative 'validation/schema_objects/foreign_key'

require_relative 'validation/adapters/column_database_adapter'
require_relative 'validation/adapters/column_structure_sql_adapter'
require_relative 'validation/adapters/foreign_key_database_adapter'
require_relative 'validation/adapters/foreign_key_structure_sql_adapter'

module Gitlab
  module Schema
    module Validation
      class Runner
        def initialize(structure_sql, database, validators:)
          @structure_sql = structure_sql
          @database = database
          @validators = validators
        end

        def execute
          validators.flat_map { |c| c.new(structure_sql, database).execute }
        end

        private

        attr_reader :structure_sql, :database, :validators
      end
    end
  end
end

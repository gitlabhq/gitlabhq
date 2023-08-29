# frozen_string_literal: true

module Gitlab
  module Schema
    module Validation
      class Inconsistency
        def initialize(validator_class, structure_sql_object, database_object)
          @validator_class = validator_class
          @structure_sql_object = structure_sql_object
          @database_object = database_object
        end

        def error_message
          format(validator_class::ERROR_MESSAGE, object_name)
        end

        def type
          validator_class.name
        end

        def object_type
          object_type = structure_sql_object&.class&.name || database_object&.class&.name

          object_type&.gsub('Gitlab::Schema::Validation::SchemaObjects::', '')
        end

        def table_name
          structure_sql_object&.table_name || database_object&.table_name
        end

        def object_name
          structure_sql_object&.name || database_object&.name
        end

        def diff
          Diffy::Diff.new(structure_sql_statement, database_statement)
        end

        def to_h
          {
            type: type,
            object_type: object_type,
            table_name: table_name,
            object_name: object_name,
            structure_sql_statement: structure_sql_statement,
            database_statement: database_statement
          }
        end

        def display
          <<~MSG
            #{'-' * 54}
            #{error_message}
            Diff:
            #{diff.to_s(:color)}
            #{'-' * 54}
          MSG
        end

        def structure_sql_statement
          return unless structure_sql_object

          "#{structure_sql_object.statement}\n"
        end

        def database_statement
          return unless database_object

          "#{database_object.statement}\n"
        end

        private

        attr_reader :validator_class, :structure_sql_object, :database_object
      end
    end
  end
end

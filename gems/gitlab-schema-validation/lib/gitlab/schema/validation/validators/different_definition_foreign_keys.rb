# frozen_string_literal: true

module Gitlab
  module Schema
    module Validation
      module Validators
        class DifferentDefinitionForeignKeys < Base
          ERROR_MESSAGE = "The %s foreign key has a different statement between structure.sql and database"

          def execute
            structure_sql.foreign_keys.filter_map do |structure_sql_fk|
              database_fk = database.fetch_foreign_key_by_name(structure_sql_fk.name)

              next if database_fk.nil?
              next if database_fk.statement == structure_sql_fk.statement

              build_inconsistency(self.class, structure_sql_fk, database_fk)
            end
          end
        end
      end
    end
  end
end

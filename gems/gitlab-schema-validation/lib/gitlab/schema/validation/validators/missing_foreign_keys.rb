# frozen_string_literal: true

module Gitlab
  module Schema
    module Validation
      module Validators
        class MissingForeignKeys < Base
          ERROR_MESSAGE = "The foreign key %s is missing from the database"

          def execute
            structure_sql.foreign_keys.filter_map do |structure_sql_fk|
              next if database.foreign_key_exists?(structure_sql_fk.name)

              build_inconsistency(self.class, structure_sql_fk, nil)
            end
          end
        end
      end
    end
  end
end

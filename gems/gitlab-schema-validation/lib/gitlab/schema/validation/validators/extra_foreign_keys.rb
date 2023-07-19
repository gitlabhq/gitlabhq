# frozen_string_literal: true

module Gitlab
  module Schema
    module Validation
      module Validators
        class ExtraForeignKeys < Base
          ERROR_MESSAGE = "The foreign key %s is present in the database, but not in the structure.sql file"

          def execute
            database.foreign_keys.filter_map do |database_fk|
              next if structure_sql.foreign_key_exists?(database_fk.name)

              build_inconsistency(self.class, nil, database_fk)
            end
          end
        end
      end
    end
  end
end

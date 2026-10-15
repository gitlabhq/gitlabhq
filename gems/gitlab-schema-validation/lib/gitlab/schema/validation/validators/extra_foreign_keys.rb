# frozen_string_literal: true

module Gitlab
  module Schema
    module Validation
      module Validators
        class ExtraForeignKeys < Base
          ERROR_MESSAGE = "The foreign key %s is present in the database, but not in the structure.sql file"

          # Temporary foreign key of an integer-to-bigint conversion, on the column its cleanup migration drops.
          BIGINT_CONVERSION_FOREIGN_KEY = /FOREIGN KEY \([^)]*_convert_to_bigint\b/

          def execute
            database.foreign_keys.filter_map do |database_fk|
              next if structure_sql.foreign_key_exists?(database_fk.name)
              next if database_fk.statement.match?(BIGINT_CONVERSION_FOREIGN_KEY)

              build_inconsistency(self.class, nil, database_fk)
            end
          end
        end
      end
    end
  end
end

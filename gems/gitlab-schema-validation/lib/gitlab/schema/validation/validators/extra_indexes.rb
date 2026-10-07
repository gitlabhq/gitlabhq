# frozen_string_literal: true

module Gitlab
  module Schema
    module Validation
      module Validators
        class ExtraIndexes < Base
          ERROR_MESSAGE = 'The index %s is present in the database, but not in the structure.sql file'

          # structure.sql never has the temporary indexes of an integer-to-bigint conversion, nor this index
          # from old Rails versions.
          BIGINT_CONVERSION_INDEX = /\Abigint_idx_\h{20}\z/
          UNIQUE_SCHEMA_MIGRATIONS =
            'CREATE UNIQUE INDEX unique_schema_migrations ON public.schema_migrations USING btree (version)'

          def execute
            database.indexes.filter_map do |database_index|
              next unless index_extra?(database_index)

              build_inconsistency(self.class, nil, database_index)
            end
          end

          private

          def index_extra?(index)
            return false if expected_extra?(index)

            partition_index_matcher.extra?(index)
          end

          def expected_extra?(index)
            index.name.match?(BIGINT_CONVERSION_INDEX) || index.statement == UNIQUE_SCHEMA_MIGRATIONS
          end
        end
      end
    end
  end
end

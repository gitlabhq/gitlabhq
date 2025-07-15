# frozen_string_literal: true

module Gitlab
  module Schema
    module Validation
      module Validators
        class MissingSequences < Base
          ERROR_MESSAGE = "The sequence %s is missing from the database"

          def execute
            structure_sql.sequences.filter_map do |sequence|
              next if database.sequence_exists?(sequence.name)

              build_inconsistency(self.class, sequence, nil)
            end
          end
        end
      end
    end
  end
end

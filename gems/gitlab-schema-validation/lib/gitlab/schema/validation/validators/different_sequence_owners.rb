# frozen_string_literal: true

module Gitlab
  module Schema
    module Validation
      module Validators
        class DifferentSequenceOwners < Base
          ERROR_MESSAGE = "The sequence %s has a different owner between structure.sql and database"

          def execute
            structure_sql.sequences.filter_map do |sequence|
              database_sequence = database.fetch_sequence_by_name(sequence.name)

              next if database_sequence.nil?
              next if database_sequence.owner == sequence.owner

              build_inconsistency(self.class, sequence, database_sequence)
            end
          end
        end
      end
    end
  end
end

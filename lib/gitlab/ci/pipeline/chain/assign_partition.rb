# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class AssignPartition < Chain::Base
          include Chain::Helpers

          DEFAULT_PARTITION_ID = 100

          def perform!
            @pipeline.partition_id = find_partition_id
          end

          def break?
            @pipeline.errors.any?
          end

          private

          # TODO handle parent-child pipelines
          def find_partition_id
            DEFAULT_PARTITION_ID
          end
        end
      end
    end
  end
end

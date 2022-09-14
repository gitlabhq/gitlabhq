# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class AssignPartition < Chain::Base
          include Chain::Helpers

          def perform!
            @pipeline.partition_id = find_partition_id
          end

          def break?
            @pipeline.errors.any?
          end

          private

          # TODO handle parent-child pipelines
          def find_partition_id
            ::Ci::Pipeline.current_partition_value
          end
        end
      end
    end
  end
end

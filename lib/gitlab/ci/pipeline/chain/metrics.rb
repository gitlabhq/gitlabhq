# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class Metrics < Chain::Base
          def perform!
            counter.increment(source: @pipeline.source)
          end

          def break?
            false
          end

          def counter
            ::Gitlab::Ci::Pipeline::Metrics.pipelines_created_counter
          end
        end
      end
    end
  end
end

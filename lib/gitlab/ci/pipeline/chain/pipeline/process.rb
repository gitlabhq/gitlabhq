# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        module Pipeline
          # After pipeline has been successfully created we can start processing it.
          class Process < Chain::Base
            def perform!
              ::Ci::ProcessPipelineService
                .new(@pipeline)
                .execute
            end

            def break?
              false
            end
          end
        end
      end
    end
  end
end

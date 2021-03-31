# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        module Pipeline
          # After pipeline has been successfully created we can start processing it.
          class Process < Chain::Base
            def perform!
              if ::Feature.enabled?(:ci_async_initial_pipeline_processing, project, default_enabled: :yaml)
                ::Ci::InitialPipelineProcessWorker.perform_async(pipeline.id)
              else
                ::Ci::ProcessPipelineService.new(pipeline).execute
              end
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

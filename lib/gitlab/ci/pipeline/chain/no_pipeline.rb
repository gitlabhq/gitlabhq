# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        class NoPipeline < Chain::Base
          include Chain::Helpers

          def perform!
            return if Feature.disabled?(:ci_no_pipeline_push_option, project)

            handle_pipeline_failure(:filtered_by_no_pipeline) if no_pipeline?
          end

          def break?
            Feature.enabled?(:ci_no_pipeline_push_option, project) && no_pipeline?
          end

          private

          def no_pipeline?
            @command.push_options.no_pipeline?
          end
        end
      end
    end
  end
end

Gitlab::Ci::Pipeline::Chain::NoPipeline.prepend_mod

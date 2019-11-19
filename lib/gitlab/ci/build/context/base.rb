# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      module Context
        class Base
          attr_reader :pipeline

          def initialize(pipeline)
            @pipeline = pipeline
          end

          def variables
            raise NotImplementedError
          end

          protected

          def pipeline_attributes
            {
              pipeline: pipeline,
              project: pipeline.project,
              user: pipeline.user,
              ref: pipeline.ref,
              tag: pipeline.tag,
              trigger_request: pipeline.legacy_trigger,
              protected: pipeline.protected_ref?
            }
          end
        end
      end
    end
  end
end

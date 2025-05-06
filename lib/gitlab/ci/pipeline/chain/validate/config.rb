# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        module Validate
          class Config < Chain::Base
            include Chain::Helpers

            def perform!
              return unless @command.inputs
              return unless @command.inputs.size > ::Ci::Pipeline::INPUTS_LIMIT

              error("There cannot be more than #{::Ci::Pipeline::INPUTS_LIMIT} inputs")
            end

            def break?
              @pipeline.errors.any?
            end
          end
        end
      end
    end
  end
end

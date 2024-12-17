# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        module PipelineExecutionPolicies
          class EvaluatePolicies < Chain::Base
            # rubocop:disable Gitlab/NoCodeCoverageComment -- EE module is tested
            # :nocov:
            def perform!
              # to be overridden in EE
            end

            def break?
              false # to be overridden in EE
            end
            # :nocov:
            # rubocop:enable Gitlab/NoCodeCoverageComment
          end
        end
      end
    end
  end
end

Gitlab::Ci::Pipeline::Chain::PipelineExecutionPolicies::EvaluatePolicies.prepend_mod

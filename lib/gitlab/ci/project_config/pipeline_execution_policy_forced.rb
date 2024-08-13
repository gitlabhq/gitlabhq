# frozen_string_literal: true

module Gitlab
  module Ci
    class ProjectConfig
      class PipelineExecutionPolicyForced < Gitlab::Ci::ProjectConfig::Source
        # rubocop:disable Gitlab/NoCodeCoverageComment -- overridden and tested in EE
        # :nocov:
        def content
          nil
        end
        # :nocov:
        # rubocop:enable Gitlab/NoCodeCoverageComment

        def source
          :pipeline_execution_policy_forced
        end
      end
    end
  end
end

Gitlab::Ci::ProjectConfig::PipelineExecutionPolicyForced.prepend_mod

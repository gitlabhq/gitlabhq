# frozen_string_literal: true

module Gitlab
  module Ci
    class ProjectConfig
      class SecurityPolicyDefault < Gitlab::Ci::ProjectConfig::Source
        def initialize(
          project:, pipeline_source: nil, triggered_for_branch: false, ref: nil, pipeline_policy_context: nil)
          @project = project
          @pipeline_source = pipeline_source
          @triggered_for_branch = triggered_for_branch
          @ref = ref
          @pipeline_policy_context = pipeline_policy_context
        end

        # rubocop:disable Gitlab/NoCodeCoverageComment -- overridden and tested in EE
        # :nocov:
        def content
          nil
        end
        # :nocov:
        # rubocop:enable Gitlab/NoCodeCoverageComment

        def source
          :security_policies_default_source
        end
      end
    end
  end
end

Gitlab::Ci::ProjectConfig::SecurityPolicyDefault.prepend_mod

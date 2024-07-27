# frozen_string_literal: true

module Gitlab
  module Ci
    class ProjectConfig
      class SecurityPolicyDefault < Gitlab::Ci::ProjectConfig::Source
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

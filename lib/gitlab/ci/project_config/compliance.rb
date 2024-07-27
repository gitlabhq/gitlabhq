# frozen_string_literal: true

module Gitlab
  module Ci
    class ProjectConfig
      class Compliance < Gitlab::Ci::ProjectConfig::Source
        # rubocop:disable Gitlab/NoCodeCoverageComment -- overridden and tested in EE
        # :nocov:
        def content
          nil
        end
        # :nocov:
        # rubocop:enable Gitlab/NoCodeCoverageComment

        def internal_include_prepended?
          true
        end

        def source
          :compliance_source
        end
      end
    end
  end
end

Gitlab::Ci::ProjectConfig::Compliance.prepend_mod

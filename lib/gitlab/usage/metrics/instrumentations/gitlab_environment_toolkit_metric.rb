# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class GitlabEnvironmentToolkitMetric < GenericMetric
          value do
            Gitlab::CurrentSettings.gitlab_environment_toolkit_instance
          end
        end
      end
    end
  end
end

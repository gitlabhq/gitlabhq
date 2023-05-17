# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class GitlabDedicatedMetric < GenericMetric
          value do
            Gitlab::CurrentSettings.gitlab_dedicated_instance
          end
        end
      end
    end
  end
end

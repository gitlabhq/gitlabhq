# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class SnowplowConfiguredToGitlabCollectorMetric < GenericMetric
          GITLAB_SNOWPLOW_COLLECTOR_HOSTNAME = 'snowplowprd.trx.gitlab.net'

          def value
            Gitlab::CurrentSettings.snowplow_collector_hostname == GITLAB_SNOWPLOW_COLLECTOR_HOSTNAME
          end
        end
      end
    end
  end
end

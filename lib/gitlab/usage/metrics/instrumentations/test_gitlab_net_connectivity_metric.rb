# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class TestGitlabNetConnectivityMetric < GenericMetric
          GITLAB_NET_TEST_URL = 'https://snowplowstg.trx.gitlab.net/test_connectivity/'

          value do
            if Gitlab.dev_or_test_env?
              false
            elsif ::ServicePing::ServicePingSettings.enabled_and_consented?
              # To prevent instances that didn't enable or consent to sending Service Ping from sending a request
              # while Service Ping is generated
              Gitlab::HTTP.post("#{GITLAB_NET_TEST_URL}#{Gitlab::CurrentSettings.uuid}")
              true
            else
              false
            end
          rescue StandardError
            false
          end
        end
      end
    end
  end
end

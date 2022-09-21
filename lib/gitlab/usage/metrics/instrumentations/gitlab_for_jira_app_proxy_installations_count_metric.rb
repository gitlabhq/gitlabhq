# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class GitlabForJiraAppProxyInstallationsCountMetric < DatabaseMetric
          operation :count

          relation { JiraConnectInstallation.proxy_installations }
        end
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class GitlabForJiraAppDirectInstallationsCountMetric < DatabaseMetric
          operation :count

          relation { JiraConnectInstallation.direct_installations }
        end
      end
    end
  end
end

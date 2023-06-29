# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class CountProjectsWithJiraDvcsIntegrationMetric < DatabaseMetric
          operation :count

          def initialize(metric_definition)
            super

            raise ArgumentError, "option 'cloud' must be a boolean" unless [true, false].include?(options[:cloud])
          end

          relation do |options|
            ProjectFeatureUsage.with_jira_dvcs_integration_enabled(cloud: options[:cloud])
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module Usage
    module Metrics
      module Instrumentations
        class JiraActiveIntegrationsMetric < DatabaseMetric
          operation :count

          def initialize(metric_definition)
            super

            deployment_type = options[:deployment_type]

            return if deployment_type.in?(allowed_types)

            raise ArgumentError, "deployment_type '#{deployment_type}' must be one of: #{allowed_types.join(', ')}"
          end

          relation do |options|
            ::Integrations::Jira
              .active
              .joins(:jira_tracker_data)
              .where(jira_tracker_data: { deployment_type: options[:deployment_type] })
          end

          private

          def allowed_types
            Integrations::JiraTrackerData.deployment_types.keys
          end
        end
      end
    end
  end
end

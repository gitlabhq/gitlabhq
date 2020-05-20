# frozen_string_literal: true

# Service for managing alert counts and cache updates.
module Types
  module AlertManagement
    class AlertStatusCountsType < BaseObject
      graphql_name 'AlertManagementAlertStatusCountsType'
      description "Represents total number of alerts for the represented categories"

      authorize :read_alert_management_alert

      ::Gitlab::AlertManagement::AlertStatusCounts::STATUSES.each_key do |status|
        field status,
              GraphQL::INT_TYPE,
              null: true,
              description: "Number of alerts with status #{status.upcase} for the project"
      end

      field :open,
            GraphQL::INT_TYPE,
            null: true,
            description: 'Number of alerts with status TRIGGERED or ACKNOWLEDGED for the project'

      field :all,
            GraphQL::INT_TYPE,
            null: true,
            description: 'Total number of alerts for the project'
    end
  end
end

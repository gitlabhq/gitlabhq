# frozen_string_literal: true

# Service for managing alert counts and cache updates.
module Types
  module AlertManagement
    class AlertStatusCountsType < BaseObject
      graphql_name 'AlertManagementAlertStatusCountsType'
      description "Represents total number of alerts for the represented categories"

      authorize :read_alert_management_alert

      ::AlertManagement::Alert.status_names.each do |status|
        field status,
          GraphQL::Types::Int,
          null: true,
          description: "Number of alerts with status #{status.to_s.upcase} for the project"
      end

      field :open,
        GraphQL::Types::Int,
        null: true,
        description: 'Number of alerts with status TRIGGERED or ACKNOWLEDGED for the project.'

      field :all,
        GraphQL::Types::Int,
        null: true,
        description: 'Total number of alerts for the project.'
    end
  end
end

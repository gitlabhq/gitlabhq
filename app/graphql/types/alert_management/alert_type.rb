# frozen_string_literal: true

module Types
  module AlertManagement
    class AlertType < BaseObject
      graphql_name 'AlertManagementAlert'
      description "Describes an alert from the project's Alert Management"

      implements(Types::Notes::NoteableType)

      authorize :read_alert_management_alert

      field :iid,
            GraphQL::ID_TYPE,
            null: false,
            description: 'Internal ID of the alert'

      field :issue_iid,
            GraphQL::ID_TYPE,
            null: true,
            description: 'Internal ID of the GitLab issue attached to the alert'

      field :title,
            GraphQL::STRING_TYPE,
            null: true,
            description: 'Title of the alert'

      field :description,
            GraphQL::STRING_TYPE,
            null: true,
            description: 'Description of the alert'

      field :severity,
            AlertManagement::SeverityEnum,
            null: true,
            description: 'Severity of the alert'

      field :status,
            AlertManagement::StatusEnum,
            null: true,
            description: 'Status of the alert'

      field :service,
            GraphQL::STRING_TYPE,
            null: true,
            description: 'Service the alert came from'

      field :monitoring_tool,
            GraphQL::STRING_TYPE,
            null: true,
            description: 'Monitoring tool the alert came from'

      field :hosts,
            [GraphQL::STRING_TYPE],
            null: true,
            description: 'List of hosts the alert came from'

      field :started_at,
            Types::TimeType,
            null: true,
            description: 'Timestamp the alert was raised'

      field :ended_at,
            Types::TimeType,
            null: true,
            description: 'Timestamp the alert ended'

      field :event_count,
            GraphQL::INT_TYPE,
            null: true,
            description: 'Number of events of this alert',
            method: :events

      field :details,
            GraphQL::Types::JSON,
            null: true,
            description: 'Alert details'

      field :created_at,
            Types::TimeType,
            null: true,
            description: 'Timestamp the alert was created'

      field :updated_at,
            Types::TimeType,
            null: true,
            description: 'Timestamp the alert was last updated'

      field :assignees,
            Types::UserType.connection_type,
            null: true,
            description: 'Assignees of the alert'

      def assignees
        return User.none unless Feature.enabled?(:alert_assignee, object.project)

        object.assignees
      end
    end
  end
end

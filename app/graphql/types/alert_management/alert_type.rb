# frozen_string_literal: true

module Types
  module AlertManagement
    class AlertType < BaseObject
      graphql_name 'AlertManagementAlert'
      description "Describes an alert from the project's Alert Management"

      present_using ::AlertManagement::AlertPresenter

      implements Types::Notes::NoteableInterface
      implements Types::TodoableInterface

      authorize :read_alert_management_alert

      field :id,
        GraphQL::Types::ID,
        null: false,
        description: 'ID of the alert.'

      field :iid,
        GraphQL::Types::String,
        null: false,
        description: 'Internal ID of the alert.'

      field :issue_iid,
        GraphQL::Types::String,
        null: true,
        deprecated: { reason: 'Use issue field', milestone: '13.10' },
        description: 'Internal ID of the GitLab issue attached to the alert.'

      field :issue,
        Types::IssueType,
        null: true,
        description: 'Issue attached to the alert.'

      field :title,
        GraphQL::Types::String,
        null: true,
        description: 'Title of the alert.'

      field :description,
        GraphQL::Types::String,
        null: true,
        description: 'Description of the alert.'

      field :severity,
        AlertManagement::SeverityEnum,
        null: true,
        description: 'Severity of the alert.'

      field :status,
        AlertManagement::StatusEnum,
        null: true,
        description: 'Status of the alert.',
        method: :status_name

      field :service,
        GraphQL::Types::String,
        null: true,
        description: 'Service the alert came from.'

      field :monitoring_tool,
        GraphQL::Types::String,
        null: true,
        description: 'Monitoring tool the alert came from.'

      field :hosts,
        [GraphQL::Types::String],
        null: true,
        description: 'List of hosts the alert came from.'

      field :started_at,
        Types::TimeType,
        null: true,
        description: 'Timestamp the alert was raised.'

      field :ended_at,
        Types::TimeType,
        null: true,
        description: 'Timestamp the alert ended.'

      field :environment,
        Types::EnvironmentType,
        null: true,
        description: 'Environment for the alert.'

      field :event_count,
        GraphQL::Types::Int,
        null: true,
        description: 'Number of events of the alert.',
        method: :events

      field :details, # rubocop:disable Graphql/JSONType
        GraphQL::Types::JSON,
        null: true,
        description: 'Alert details.'

      field :created_at,
        Types::TimeType,
        null: true,
        description: 'Timestamp the alert was created.'

      field :updated_at,
        Types::TimeType,
        null: true,
        description: 'Timestamp the alert was last updated.'

      field :assignees,
        Types::UserType.connection_type,
        null: true,
        description: 'Assignees of the alert.'

      field :metrics_dashboard_url,
        GraphQL::Types::String,
        null: true,
        description: 'URL for metrics embed for the alert.',
        deprecated: { reason: 'Returns no data. Underlying feature was removed in 16.0',
                      milestone: '16.0' }
      field :runbook,
        GraphQL::Types::String,
        null: true,
        description: 'Runbook for the alert as defined in alert details.'

      field :todos,
        Types::TodoType.connection_type,
        description: 'To-do items of the current user for the alert.',
        resolver: Resolvers::TodosResolver

      field :details_url,
        GraphQL::Types::String,
        null: false,
        description: 'URL of the alert detail page.'

      field :prometheus_alert,
        Types::PrometheusAlertType,
        null: true,
        description: 'Alert condition for Prometheus.',
        deprecated: {
          reason: 'Returns no data. Underlying feature was removed in 16.0',
          milestone: '17.3'
        }

      field :web_url,
        GraphQL::Types::String,
        method: :details_url,
        null: false,
        description: 'URL of the alert.'

      def metrics_dashboard_url
        nil
      end

      def prometheus_alert
        nil
      end
    end
  end
end

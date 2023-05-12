# frozen_string_literal: true

module Types
  class EnvironmentType < BaseObject
    graphql_name 'Environment'
    description 'Describes where code is deployed for a project'

    present_using ::EnvironmentPresenter

    authorize :read_environment

    expose_permissions Types::PermissionTypes::Environment,
      description: 'Permissions for the current user on the resource. '\
                   'This field can only be resolved for one environment in any single request.' do
      extension ::Gitlab::Graphql::Limit::FieldCallCount, limit: 1
    end

    field :name, GraphQL::Types::String, null: false,
                                         description: 'Human-readable name of the environment.'

    field :id, GraphQL::Types::ID, null: false,
                                   description: 'ID of the environment.'

    field :state, GraphQL::Types::String, null: false,
                                          description: 'State of the environment, for example: available/stopped.'

    field :path, GraphQL::Types::String, null: false,
                                         description: 'Path to the environment.'

    field :slug, GraphQL::Types::String,
      description: 'Slug of the environment.'

    field :external_url, GraphQL::Types::String, null: true,
                                                 description: 'External URL of the environment.'

    field :created_at, Types::TimeType,
      description: 'When the environment was created.'

    field :updated_at, Types::TimeType,
      description: 'When the environment was updated.'

    field :auto_stop_at, Types::TimeType,
      description: 'When the environment is going to be stopped automatically.'

    field :auto_delete_at, Types::TimeType,
      description: 'When the environment is going to be deleted automatically.'

    field :tier, Types::DeploymentTierEnum,
      description: 'Deployment tier of the environment.'

    field :environment_type, GraphQL::Types::String,
      description: 'Folder name of the environment.'

    field :metrics_dashboard, Types::Metrics::DashboardType, null: true,
                                                             description: 'Metrics dashboard schema for the environment.',
                                                             resolver: Resolvers::Metrics::DashboardResolver,
                                                             deprecated: { reason: 'Returns no data. Underlying feature was removed in 16.0', milestone: '16.0' }

    field :latest_opened_most_severe_alert,
          Types::AlertManagement::AlertType,
          null: true,
          description: 'Most severe open alert for the environment. If multiple alerts have equal severity, the most recent is returned.'

    field :deployments,
          Types::DeploymentType.connection_type,
          null: true,
          description: 'Deployments of the environment. This field can only be resolved for one environment in any single request.',
          resolver: Resolvers::DeploymentsResolver do
            extension ::Gitlab::Graphql::Limit::FieldCallCount, limit: 1
          end

    field :last_deployment,
          Types::DeploymentType,
          description: 'Last deployment of the environment.',
          resolver: Resolvers::Environments::LastDeploymentResolver

    field :deploy_freezes,
          [Types::Ci::FreezePeriodType],
          null: true,
          description: 'Deployment freeze periods of the environment.'

    def tier
      object.tier.to_sym
    end
  end
end

Types::EnvironmentType.prepend_mod_with('Types::EnvironmentType')

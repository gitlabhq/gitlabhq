# frozen_string_literal: true

module Mutations
  module Environments
    class Create < ::Mutations::BaseMutation
      graphql_name 'EnvironmentCreate'
      description 'Create an environment.'

      include FindsProject

      authorize :create_environment

      argument :project_path,
        GraphQL::Types::ID,
        required: true,
        description: 'Full path of the project.'

      argument :name,
        GraphQL::Types::String,
        required: true,
        description: 'Name of the environment.'

      argument :description,
        GraphQL::Types::String,
        required: false,
        description: 'Description of the environment.'

      argument :external_url,
        GraphQL::Types::String,
        required: false,
        description: 'External URL of the environment.'

      argument :tier,
        Types::DeploymentTierEnum,
        required: false,
        description: 'Tier of the environment.'

      argument :cluster_agent_id,
        ::Types::GlobalIDType[::Clusters::Agent],
        required: false,
        description: 'Cluster agent of the environment.'

      argument :kubernetes_namespace,
        GraphQL::Types::String,
        required: false,
        description: 'Kubernetes namespace of the environment.'

      argument :flux_resource_path,
        GraphQL::Types::String,
        required: false,
        description: 'Flux resource path of the environment.'

      argument :auto_stop_setting,
        Types::Environments::AutoStopSettingEnum,
        required: false,
        description: 'Auto stop setting of the environment.'

      field :environment,
        Types::EnvironmentType,
        null: true,
        description: 'Created environment.'

      def resolve(project_path:, **kwargs)
        project = authorized_find!(project_path)

        kwargs[:cluster_agent] = GitlabSchema.find_by_gid(kwargs.delete(:cluster_agent_id))&.sync

        response = ::Environments::CreateService.new(project, current_user, kwargs).execute

        if response.success?
          { environment: response.payload[:environment], errors: [] }
        else
          { environment: response.payload[:environment], errors: response.errors }
        end
      end
    end
  end
end

# frozen_string_literal: true

module Mutations
  module Environments
    class Update < ::Mutations::BaseMutation
      graphql_name 'EnvironmentUpdate'
      description 'Update an environment.'

      authorize :update_environment

      argument :id,
        ::Types::GlobalIDType[::Environment],
        required: true,
        description: 'Global ID of the environment to update.'

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
        description: 'Environment after attempt to update.'

      def resolve(id:, **kwargs)
        environment = authorized_find!(id: id)

        convert_cluster_agent_id(kwargs)

        response = ::Environments::UpdateService.new(environment.project, current_user, kwargs).execute(environment)

        if response.success?
          { environment: response.payload[:environment], errors: [] }
        else
          { environment: response.payload[:environment], errors: response.errors }
        end
      end

      private

      def convert_cluster_agent_id(kwargs)
        return unless kwargs.key?(:cluster_agent_id)

        kwargs[:cluster_agent] = if kwargs[:cluster_agent_id]
                                   ::Clusters::Agent.find_by_id(kwargs[:cluster_agent_id].model_id)
                                 end
      end
    end
  end
end

# frozen_string_literal: true

module Mutations
  module Clusters
    module AgentUrlConfigurations
      class Delete < BaseMutation
        graphql_name 'ClusterAgentUrlConfigurationDelete'

        authorize :admin_cluster

        UrlConfigurationID = ::Types::GlobalIDType[::Clusters::Agents::UrlConfiguration]

        argument :id, UrlConfigurationID,
          required: true,
          description: 'Global ID of the agent URL configuration that will be deleted.'

        def resolve(id:)
          url_cfg = authorized_find!(id: id)

          result = ::Clusters::Agents::DeleteUrlConfigurationService
            .new(agent: url_cfg.agent, current_user: current_user, url_configuration: url_cfg)
            .execute

          {
            errors: Array.wrap(result.message)
          }
        end
      end
    end
  end
end

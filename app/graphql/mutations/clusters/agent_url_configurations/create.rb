# frozen_string_literal: true

module Mutations
  module Clusters
    module AgentUrlConfigurations
      class Create < BaseMutation
        graphql_name 'ClusterAgentUrlConfigurationCreate'

        authorize :create_cluster

        ClusterAgentID = ::Types::GlobalIDType[::Clusters::Agent]

        argument :cluster_agent_id,
          ClusterAgentID,
          required: true,
          description: 'Global ID of the cluster agent that will be associated with the new URL configuration.'

        argument :url,
          GraphQL::Types::String,
          required: true,
          description: 'URL for the new URL configuration.'

        argument :client_cert,
          GraphQL::Types::String,
          required: false,
          description: 'Base64-encoded client certificate in PEM format if mTLS authentication should be used. ' \
            'Must be provided with `client_key`.'

        argument :client_key,
          GraphQL::Types::String,
          required: false,
          description: 'Base64-encoded client key in PEM format if mTLS authentication should be used. ' \
            'Must be provided with `client_cert`.'

        argument :ca_cert,
          GraphQL::Types::String,
          required: false,
          description: 'Base64-encoded CA certificate in PEM format to verify the agent endpoint.'

        argument :tls_host,
          GraphQL::Types::String,
          required: false,
          description: 'TLS host name to verify the server name in agent endpoint certificate.'

        field :url_configuration,
          Types::Clusters::AgentUrlConfigurationType,
          null: true,
          description: 'URL configuration created after mutation.'

        def resolve(args)
          cluster_agent = authorized_find!(id: args[:cluster_agent_id])

          url_cfg_params = args

          url_cfg_params[:ca_cert] = Base64.decode64(url_cfg_params[:ca_cert]) if url_cfg_params[:ca_cert]
          if url_cfg_params[:client_cert]
            url_cfg_params[:client_cert] =
              Base64.decode64(url_cfg_params[:client_cert])
          end

          url_cfg_params[:client_key] = Base64.decode64(url_cfg_params[:client_key]) if url_cfg_params[:client_key]

          result = ::Clusters::Agents::CreateUrlConfigurationService.new(
            agent: cluster_agent,
            current_user: current_user,
            params: url_cfg_params
          ).execute

          payload = result.payload

          {
            url_configuration: payload[:url_configuration],
            errors: Array.wrap(result.message)
          }
        end
      end
    end
  end
end

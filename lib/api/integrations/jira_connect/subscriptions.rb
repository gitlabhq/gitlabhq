# frozen_string_literal: true

module API
  class Integrations
    module JiraConnect
      class Subscriptions < ::API::Base
        feature_category :integrations

        before { authenticate! }

        namespace :integrations do
          namespace :jira_connect do
            resource :subscriptions do
              desc 'Subscribe a namespace to a JiraConnectInstallation'
              params do
                requires :jwt, type: String, desc: 'JWT token for authorization with the Jira Connect installation'
                requires :namespace_path, type: String, desc: 'Path for the namespace that should be subscribed'
              end
              post do
                not_found! unless Feature.enabled?(:jira_connect_oauth, current_user)

                jwt = Atlassian::JiraConnect::Jwt::Symmetric.new(params[:jwt])
                installation = JiraConnectInstallation.find_by_client_key(jwt.iss_claim)

                if !installation || !jwt.valid?(installation.shared_secret) || !jwt.verify_context_qsh_claim
                  unauthorized!('JWT authentication failed')
                end

                jira_user = installation.client.user_info(jwt.sub_claim)

                result = ::JiraConnectSubscriptions::CreateService.new(
                  installation,
                  current_user,
                  namespace_path: params['namespace_path'],
                  jira_user: jira_user
                ).execute

                if result[:status] == :success
                  status :created
                  { success: true }
                else
                  render_api_error!(result[:message], result[:http_status])
                end
              end
            end
          end
        end
      end
    end
  end
end

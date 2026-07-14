# frozen_string_literal: true

module API
  class Integrations
    module JiraForge
      # Namespace subscriptions for the native GitLab for Jira (Forge) app: the
      # Forge-only counterpart of the Connect subscriptions surface. Reuses
      # JiraConnectSubscriptions::{Create,Destroy}Service.
      class Subscriptions < ::API::Base
        feature_category :integrations

        before do
          # Resolve the org from the header (for cell routing) without touching
          # current_user, so the FIT bearer is not validated as a GitLab token.
          set_current_organization(user: nil)
        end

        helpers ::API::Integrations::JiraForge::Helpers

        namespace :integrations do
          namespace :jira_forge do
            resource :subscriptions do
              desc 'Create a GitLab for Jira (Forge) namespace subscription' do
                detail 'Subscribes a GitLab namespace to the Forge installation so its ' \
                  'development data syncs to Jira. Authenticated as the GitLab user (OAuth); ' \
                  'the Jira installation and user are resolved from the Forge invocation context.'
                success ::API::Entities::BasicSuccess
                failure [
                  { code: 401, message: 'Unauthorized' },
                  { code: 403, message: 'Forbidden' },
                  { code: 404, message: 'Not found' },
                  { code: 422, message: 'Unprocessable entity' }
                ]
                tags %w[jira_forge_subscriptions]
              end
              params do
                requires :namespace_path, type: String, limit: 255,
                  desc: 'Path of the namespace to subscribe'
              end
              route_setting :lifecycle, :experiment
              route_setting :authorization, skip_granular_token_authorization: :jira_forge_app_auth
              post do
                authenticate!

                installation = forge_oauth_installation
                unauthorized!('Jira installation not found for the provided cloud id') unless installation

                result = ::JiraConnectSubscriptions::CreateService.new(
                  installation,
                  current_user,
                  namespace_path: params[:namespace_path],
                  jira_user: forge_jira_user(installation)
                ).execute

                if result[:status] == :success
                  status :created
                  # organization_id lets the Forge app persist the org for cell routing.
                  { success: true, organization_id: installation.organization_id }
                else
                  render_api_error!(result[:message], result[:http_status])
                end
              end

              desc 'List GitLab for Jira (Forge) namespace subscriptions' do
                detail 'Lists the GitLab namespaces subscribed to the Forge installation.'
                success ::JiraConnect::SubscriptionEntity
                failure [{ code: 401, message: 'Unauthorized' }]
                tags %w[jira_forge_subscriptions]
              end
              route_setting :lifecycle, :experiment
              route_setting :authorization, skip_granular_token_authorization: :jira_forge_app_auth
              get do
                installation = forge_installation
                unauthorized!('Forge invocation token authentication failed') unless installation

                subscriptions = installation.subscriptions.preload_namespace_route
                { subscriptions: ::JiraConnect::SubscriptionEntity.represent(subscriptions).as_json }
              end

              desc 'Delete a GitLab for Jira (Forge) namespace subscription' do
                detail 'Unsubscribes a GitLab namespace from the Forge installation.'
                success ::API::Entities::BasicSuccess
                failure [
                  { code: 401, message: 'Unauthorized' },
                  { code: 403, message: 'Forbidden' },
                  { code: 404, message: 'Not found' },
                  { code: 422, message: 'Unprocessable entity' }
                ]
                tags %w[jira_forge_subscriptions]
              end
              params do
                requires :id, type: Integer, desc: 'ID of the subscription to delete'
              end
              route_setting :lifecycle, :experiment
              route_setting :authorization, skip_granular_token_authorization: :jira_forge_app_auth
              delete ':id' do
                installation = forge_installation
                unauthorized!('Forge invocation token authentication failed') unless installation

                subscription = installation.subscriptions.find_by_id(params[:id])
                not_found!('Subscription') unless subscription

                result = ::JiraConnectSubscriptions::DestroyService.new(
                  subscription, forge_jira_user(installation)
                ).execute

                if result.success?
                  { success: true }
                else
                  render_api_error!(result.message, Rack::Utils.status_code(result.reason))
                end
              end
            end
          end
        end
      end
    end
  end
end

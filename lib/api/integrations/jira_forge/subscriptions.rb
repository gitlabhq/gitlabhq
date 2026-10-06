# frozen_string_literal: true

module API
  class Integrations
    module JiraForge
      # Namespace subscriptions for the native GitLab for Jira (Forge) app: the
      # Forge-only counterpart of the Connect subscriptions surface. Reuses
      # JiraConnectSubscriptions::{Create,Destroy}Service.
      class Subscriptions < ::API::Base
        feature_category :integrations

        helpers ::API::Integrations::JiraForge::Helpers

        helpers do
          # Native Forge first-link, everything on ONE app-context (invokeRemote)
          # call, all server-verified:
          #
          # - cloud_id / apiBaseUrl / principal from the FIT (bearer, RS256 vs
          #   the Atlassian JWKS) -- not spoofable headers;
          # - Jira site-admin checked BY GITLAB against Jira, using the app
          #   system token riding the same call (X-Forge-Oauth-System);
          # - the GitLab user from the signed delegation token minted at sign-in
          #   (Integrations::JiraForge::UserDelegationToken), scope-checked against the
          #   FIT, for the namespace checks.
          #
          # Creation is deferred to here (not the Connect `installed` event) so
          # the installation lands on the correct organization/cell, resolved
          # from the linked namespace. The apiBaseUrl + system token are stored
          # at creation, so the installation is forge_direct? immediately.
          # Returns [installation, user, jira_user].
          def forge_first_link_installation!
            fit = valid_forge_token
            unless fit&.installation_id && fit.cloud_id && fit.api_base_url
              unauthorized!('Forge invocation token authentication failed')
            end

            system_token = headers['X-Forge-Oauth-System'].presence
            render_api_error!('Missing Forge system token', 400) if system_token.blank?

            user = forge_delegated_user(fit)
            unauthorized!('Invalid or expired GitLab user delegation') unless user

            jira_user = forge_native_jira_user(fit.api_base_url, system_token, fit.principal)
            forbidden!(jira_admin_error) unless jira_user&.jira_admin?

            # Resolve + authorize the namespace before creating anything, so a
            # user who cannot see or link it never creates an installation row.
            namespace = Namespace.find_by_full_path(params[:namespace_path])
            unless namespace && can?(user, :read_namespace, namespace)
              render_api_error!(s_('JiraConnect|Namespace not found. Check the group path and try again.'), 404)
            end

            unless can?(user, :create_jira_connect_subscription, namespace)
              forbidden!(s_('JiraConnect|You do not have permission to link this namespace. ' \
                'You must be a Maintainer or Owner of the group.'))
            end

            installation = ::Integrations::JiraForge::FindOrCreateInstallationService.execute(
              installation_id: fit.installation_id,
              cloud_id: fit.cloud_id,
              organization_id: namespace.organization_id,
              jira_api_base_url: fit.api_base_url,
              forge_system_token: system_token
            )
            render_api_error!(installation.errors.full_messages.to_sentence, 422) if installation.errors.any?

            [installation, user, jira_user]
          end
        end

        namespace :integrations do
          namespace :jira_forge do
            resource :subscriptions do
              desc 'Create a GitLab for Jira (Forge) namespace subscription' do
                detail 'Subscribes a GitLab namespace to the Forge installation so its ' \
                  'development data syncs to Jira. Authenticated by the Forge Invocation Token ' \
                  '(app-context call); the GitLab user is bound via the signed delegation token ' \
                  'from the user_delegation endpoint, and the Jira site-admin check runs against ' \
                  'Jira with the app system token riding the call.'
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
                  desc: 'Path of the namespace to subscribe.'
              end
              route_setting :lifecycle, :experiment
              route_setting :authorization, skip_granular_token_authorization: :jira_forge_app_auth
              post do
                installation, user, jira_user = forge_first_link_installation!

                result = ::JiraConnectSubscriptions::CreateService.new(
                  installation,
                  user,
                  namespace_path: params[:namespace_path],
                  jira_user: jira_user
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
                requires :id, type: Integer, desc: 'ID of the subscription.'
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

            resource :user_delegation do
              desc 'Create a GitLab for Jira (Forge) user delegation token' do
                detail 'Mints a short-lived GitLab-signed token identifying the signed-in ' \
                  'GitLab user, scoped to the Jira account and site it is minted for. ' \
                  'Accepts only the OAuth token issued to the Forge app at sign-in. The ' \
                  'Forge app stores it at config-page sign-in and presents it on the ' \
                  'FIT-authenticated subscribe call, which cannot carry the user OAuth ' \
                  'token (Forge attaches the FIT only to app-context calls); the scope ' \
                  'claims must match that call\'s FIT.'
                success ::API::Entities::BasicSuccess
                failure [{ code: 401, message: 'Unauthorized' }]
                tags %w[jira_forge_user_delegation]
              end
              params do
                requires :account_id, type: String, limit: 255,
                  desc: 'Jira account id the delegation is scoped to'
                requires :cloud_id, type: String, limit: 255,
                  desc: 'Jira site (cloud) id the delegation is scoped to'
              end
              route_setting :lifecycle, :experiment
              route_setting :authorization, skip_granular_token_authorization: :jira_forge_app_auth
              post do
                authenticate!
                # Only the Forge app's OAuth sign-in may mint; a PAT or bot token cannot.
                unauthorized! unless access_token.is_a?(::OauthAccessToken)

                delegation = ::Integrations::JiraForge::UserDelegationToken.build(
                  user: current_user,
                  account_id: params[:account_id],
                  cloud_id: params[:cloud_id]
                )

                status :created
                { delegation: delegation.to_jwt }
              end
            end
          end
        end
      end
    end
  end
end

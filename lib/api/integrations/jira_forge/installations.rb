# frozen_string_literal: true

module API
  class Integrations
    module JiraForge
      # Installation administration for the native GitLab for Jira (Forge) app,
      # authenticated by the Forge Invocation Token.
      class Installations < ::API::Base
        feature_category :integrations

        helpers ::API::Integrations::JiraForge::Helpers

        namespace :integrations do
          namespace :jira_forge do
            resource :installation do
              desc 'Update the GitLab for Jira (Forge) installation instance URL' do
                detail 'Sets the GitLab instance the installation points at. Omit instance_url ' \
                  '(or send null) for GitLab.com. Requires a Jira site or organization admin.'
                success ::API::Entities::BasicSuccess
                failure [
                  { code: 401, message: 'Unauthorized' },
                  { code: 403, message: 'Forbidden' },
                  { code: 422, message: 'Unprocessable entity' }
                ]
                tags %w[jira_forge_installation]
              end
              params do
                optional :instance_url, type: String, limit: 1024,
                  desc: 'Base URL of the self-managed GitLab instance; null for GitLab.com'
              end
              route_setting :lifecycle, :experiment
              route_setting :authorization, skip_granular_token_authorization: :jira_forge_app_auth
              put do
                installation = forge_installation
                unauthorized!('Forge invocation token authentication failed') unless installation

                jira_user = forge_jira_user(installation)
                forbidden!(jira_admin_error) unless jira_user

                result = ::JiraConnectInstallations::UpdateService.execute(
                  installation,
                  jira_user,
                  { instance_url: params[:instance_url], organization_id: Current.organization.id }
                )

                if result.success?
                  { success: true }
                elsif result.reason == :forbidden
                  forbidden!(result.message)
                else
                  render_api_error!(result.message, 422)
                end
              end

              desc 'Register the GitLab for Jira (Forge) system token for direct dev-info sync' do
                detail 'Stores the Forge app system OAuth token (X-Forge-Oauth-System header) and the ' \
                  'Jira apiBaseUrl (from the FIT), so GitLab pushes dev-info directly to Jira. ' \
                  'See Atlassian::Forge::SystemTokenClient.'
                success ::API::Entities::BasicSuccess
                failure [
                  { code: 401, message: 'Unauthorized' },
                  { code: 422, message: 'Unprocessable entity' }
                ]
                tags %w[jira_forge_installation]
              end
              # The system token arrives in the X-Forge-Oauth-System header, not the body.
              route_setting :lifecycle, :experiment
              route_setting :authorization, skip_granular_token_authorization: :jira_forge_app_auth
              post 'forge_token' do
                installation = forge_installation
                unauthorized!('Forge invocation token authentication failed') unless installation

                system_token = headers['X-Forge-Oauth-System'].presence
                api_base_url = forge_api_base_url
                if system_token.blank? || api_base_url.blank?
                  render_api_error!('Missing Forge system token or apiBaseUrl', 400)
                end

                if installation.update(jira_api_base_url: api_base_url, forge_system_token: system_token)
                  { success: true }
                else
                  render_api_error!(installation.errors.full_messages.to_sentence, 422)
                end
              end

              desc 'Destroy the GitLab for Jira (Forge) installation on app uninstall' do
                detail 'Called by the Forge app preUninstall hook. A pure-native ' \
                  'install fires no Connect uninstalled event, so this is what removes the ' \
                  'installation, its subscriptions, and deactivates the linked jira_cloud_app ' \
                  'integrations. FIT authentication carries the same trust as the signed ' \
                  'Connect lifecycle event, so no Jira admin check is needed. Succeeds with ' \
                  'no change when the installation is already gone.'
                success ::API::Entities::BasicSuccess
                failure [
                  { code: 401, message: 'Unauthorized' },
                  { code: 422, message: 'Unprocessable entity' }
                ]
                tags %w[jira_forge_installation]
              end
              route_setting :lifecycle, :experiment
              route_setting :authorization, skip_granular_token_authorization: :jira_forge_app_auth
              delete do
                unauthorized!('Forge invocation token authentication failed') unless valid_forge_token

                # The Connect uninstalled event may have removed the row first.
                installation = forge_installation
                break { success: true } unless installation

                destroyed = ::JiraConnectInstallations::DestroyService.execute(
                  installation,
                  ::Gitlab::Routing.url_helpers.jira_connect_base_path,
                  ::Gitlab::Routing.url_helpers.jira_connect_events_uninstalled_path
                )

                if destroyed
                  { success: true }
                else
                  render_api_error!('Failed to destroy the installation', 422)
                end
              end
            end
          end
        end
      end
    end
  end
end

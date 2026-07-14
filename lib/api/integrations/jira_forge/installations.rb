# frozen_string_literal: true

module API
  class Integrations
    module JiraForge
      # Installation administration for the native GitLab for Jira (Forge) app,
      # authenticated by the Forge Invocation Token.
      class Installations < ::API::Base
        feature_category :integrations

        before do
          # Resolve the org from the header without touching current_user, so the
          # FIT bearer is not validated as a GitLab token.
          set_current_organization(user: nil)
        end

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
            end
          end
        end

        helpers do
          def jira_admin_error
            s_('JiraConnect|The Jira user is not a site or organization administrator. ' \
              'Check the permissions in Jira and try again.')
          end
        end
      end
    end
  end
end

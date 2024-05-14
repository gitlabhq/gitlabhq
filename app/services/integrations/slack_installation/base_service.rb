# frozen_string_literal: true

# Base class for services that handle enabling the GitLab for Slack app integration.
#
# Inheriting services should define these methods:
# - `#authorized?` return true if the user is authorized to install the app
# - `#redirect_uri` return the redirect URI for the OAuth flow
# - `#find_or_create_integration` find or create the Integrations::GitlabSlackApplication record
# - `#installation_alias` return the alias property for the SlackIntegration record
module Integrations
  module SlackInstallation
    class BaseService
      include Gitlab::Routing

      # Endpoint to initiate the OAuth flow, redirects to Slack's authorization screen
      # https://api.slack.com/authentication/oauth-v2#asking
      SLACK_AUTHORIZE_URL = 'https://slack.com/oauth/v2/authorize'

      # Endpoint to exchange the temporary authorization code for an access token
      # https://api.slack.com/authentication/oauth-v2#exchanging
      SLACK_EXCHANGE_TOKEN_URL = 'https://slack.com/api/oauth.v2.access'

      def initialize(current_user:, params:)
        @current_user = current_user
        @params = params
      end

      def execute
        unless Gitlab::CurrentSettings.slack_app_enabled
          return ServiceResponse.error(message: s_('SlackIntegration|Slack app not enabled on GitLab instance'))
        end

        return ServiceResponse.error(message: s_('SlackIntegration|Unauthorized')) unless authorized?

        begin
          slack_data = exchange_slack_token
        rescue *::Gitlab::HTTP::HTTP_ERRORS => e
          return ServiceResponse
            .error(message: s_('SlackIntegration|Error exchanging OAuth token with Slack'))
            .track_exception(as: e.class)
        end

        unless slack_data['ok']
          return ServiceResponse.error(
            message: format(
              s_('SlackIntegration|Error exchanging OAuth token with Slack: %{error}'),
              error: slack_data['error']
            )
          )
        end

        integration = find_or_create_integration!
        installation = integration.slack_integration || integration.build_slack_integration

        installation.update!(
          bot_user_id: slack_data['bot_user_id'],
          bot_access_token: slack_data['access_token'],
          team_id: slack_data.dig('team', 'id'),
          team_name: slack_data.dig('team', 'name'),
          alias: installation_alias,
          user_id: slack_data.dig('authed_user', 'id'),
          authorized_scope_names: slack_data['scope']
        )

        update_other_installations!(installation)

        PropagateIntegrationWorker.perform_async(integration.id) unless integration.project_level?

        ServiceResponse.success
      end

      private

      attr_reader :current_user, :params

      def exchange_slack_token
        query = {
          client_id: Gitlab::CurrentSettings.slack_app_id,
          client_secret: Gitlab::CurrentSettings.slack_app_secret,
          code: params[:code],
          redirect_uri: redirect_uri
        }

        Gitlab::HTTP.get(SLACK_EXCHANGE_TOKEN_URL, query: query).to_hash
      end

      # Due to our modelling (mentioned in epic 9418) we create a SlackIntegration record
      # for a Slack workspace (team_id) for every GitLab for Slack integration.
      # The repetition is redundant, and we should more correctly only create
      # a single record per workspace.
      #
      # Records that share a team_id (Slack workspace ID) should have identical bot token
      # and permission scope data. We currently paper-over the modelling problem
      # by mass-updating all records that share a team_id so they always reflect the same state.
      # for this data. This means if we release a new version of the GitLab for Slack app that has
      # a new required permission scope, the first time the workspace authorizes the new scope
      # all other records for their workspace will be updated with the latest authorization data
      # for that workspace.
      def update_other_installations!(installation)
        updatable_attributes = installation.attributes.slice(
          'user_id',
          'bot_user_id',
          'encrypted_bot_access_token',
          'encrypted_bot_access_token_iv',
          'updated_at'
        )

        SlackIntegration.by_team(installation.team_id).id_not_in(installation.id).each_batch do |batch|
          batch_ids = batch.pluck_primary_key
          batch.update_all(updatable_attributes)

          Integrations::SlackWorkspace::IntegrationApiScope.update_scopes(batch_ids, installation.slack_api_scopes)
        end
      end
    end
  end
end

# frozen_string_literal: true

module Projects
  class SlackApplicationInstallService < BaseService
    include Gitlab::Routing

    # Endpoint to initiate the OAuth flow, redirects to Slack's authorization screen
    # https://api.slack.com/authentication/oauth-v2#asking
    SLACK_AUTHORIZE_URL = 'https://slack.com/oauth/v2/authorize'

    # Endpoint to exchange the temporary authorization code for an access token
    # https://api.slack.com/authentication/oauth-v2#exchanging
    SLACK_EXCHANGE_TOKEN_URL = 'https://slack.com/api/oauth.v2.access'

    def execute
      slack_data = exchange_slack_token

      return error("Slack: #{slack_data['error']}") unless slack_data['ok']

      integration = project.gitlab_slack_application_integration \
        || project.create_gitlab_slack_application_integration!

      installation = integration.slack_integration || integration.build_slack_integration

      installation.update!(
        bot_user_id: slack_data['bot_user_id'],
        bot_access_token: slack_data['access_token'],
        team_id: slack_data.dig('team', 'id'),
        team_name: slack_data.dig('team', 'name'),
        alias: project.full_path,
        user_id: slack_data.dig('authed_user', 'id'),
        authorized_scope_names: slack_data['scope']
      )

      update_legacy_installations!(installation)

      success
    end

    private

    def exchange_slack_token
      query = {
        client_id: Gitlab::CurrentSettings.slack_app_id,
        client_secret: Gitlab::CurrentSettings.slack_app_secret,
        code: params[:code],
        # NOTE: Needs to match the `redirect_uri` passed to the authorization endpoint,
        # otherwise we get a `bad_redirect_uri` error.
        redirect_uri: slack_auth_project_settings_slack_url(project)
      }

      Gitlab::HTTP.get(SLACK_EXCHANGE_TOKEN_URL, query: query).to_hash
    end

    # Update any legacy SlackIntegration records for the Slack Workspace. Legacy SlackIntegration records
    # are any created before our Slack App was upgraded to use Granular Bot Permissions and issue a
    # bot_access_token. Any SlackIntegration records for the Slack Workspace will already have the same
    # bot_access_token.
    def update_legacy_installations!(installation)
      updatable_attributes = installation.attributes.slice(
        'user_id',
        'bot_user_id',
        'encrypted_bot_access_token',
        'encrypted_bot_access_token_iv',
        'updated_at'
      )

      SlackIntegration.by_team(installation.team_id).id_not_in(installation.id).each_batch do |batch|
        batch_ids = batch.pluck(:id) # rubocop: disable CodeReuse/ActiveRecord
        batch.update_all(updatable_attributes)

        ::Integrations::SlackWorkspace::IntegrationApiScope.update_scopes(batch_ids, installation.slack_api_scopes)
      end
    end
  end
end

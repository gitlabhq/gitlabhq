module Projects
  class SlackApplicationInstallService < BaseService
    include Gitlab::Routing

    SLACK_EXCHANGE_TOKEN_URL = 'https://slack.com/api/oauth.access'.freeze

    def execute
      slack_data = exchange_slack_token

      return error("Slack: #{slack_data['error']}") unless slack_data['ok']

      unless project.gitlab_slack_application_service
        project.create_gitlab_slack_application_service
      end

      service = project.gitlab_slack_application_service

      SlackIntegration.create!(
        service_id: service.id,
        team_id: slack_data['team_id'],
        team_name: slack_data['team_name'],
        alias: project.full_path,
        user_id: slack_data['user_id']
      )

      make_sure_chat_name_created(slack_data)

      success
    end

    def chat_responder
      Gitlab::Chat::Responder::Slack
    end

    private

    def make_sure_chat_name_created(slack_data)
      service = project.gitlab_slack_application_service

      chat_name = ChatName.find_by(
        service: service.id,
        team_id: slack_data['team_id'],
        chat_id: slack_data['user_id']
      )

      unless chat_name
        ChatName.find_or_create_by!(
          service_id: service.id,
          team_id: slack_data['team_id'],
          team_domain: slack_data['team_name'],
          chat_id: slack_data['user_id'],
          chat_name: slack_data['user_name'],
          user: current_user
        )
      end
    end

    def exchange_slack_token
      Gitlab::HTTP.get(SLACK_EXCHANGE_TOKEN_URL, query: {
        client_id: Gitlab::CurrentSettings.slack_app_id,
        client_secret: Gitlab::CurrentSettings.slack_app_secret,
        redirect_uri: slack_auth_project_settings_slack_url(project),
        code: params[:code]
      })
    end
  end
end

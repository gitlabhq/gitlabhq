# frozen_string_literal: true

# Builds the BlockKit UI JSON payload to respond to the Slack `app_home_opened` event.
#
# See:
# - https://api.slack.com/block-kit/building
# - https://api.slack.com/events/app_home_opened
module Slack
  module BlockKit
    class AppHomeOpened
      include ActionView::Helpers::AssetUrlHelper
      include Gitlab::Routing.url_helpers

      def initialize(slack_user_id, slack_workspace_id, slack_gitlab_user_connection, slack_installation)
        @slack_user_id = slack_user_id
        @slack_workspace_id = slack_workspace_id
        @slack_gitlab_user_connection = slack_gitlab_user_connection
        @slack_installation = slack_installation
      end

      def build
        {
          type: "home",
          blocks: [
            header,
            section_introduction,
            section_notifications_heading,
            section_notifications,
            section_slash_commands_heading,
            section_slash_commands,
            section_slash_commands_connect,
            section_connect_gitlab_account
          ]
        }
      end

      private

      attr_reader :slack_user_id, :slack_workspace_id, :slack_gitlab_user_connection, :slack_installation

      def header
        {
          type: "header",
          text: {
            type: "plain_text",
            text: format(
              s_("Slack|%{emoji}Welcome to GitLab for Slack!"),
              emoji: '✨ '
            ),
            emoji: true
          }
        }
      end

      def section_introduction
        section(
          format(
            s_("Slack|GitLab for Slack now supports channel-based notifications. " \
               "Let your team know when new issues are created or new CI/CD jobs are run." \
               "%{startMarkup}Learn more%{endMarkup}."),
            startMarkup: " <#{help_page_url('user/project/integrations/gitlab_slack_application.md')}|",
            endMarkup: ">"
          )
        )
      end

      def section_notifications_heading
        section(
          format(
            s_("Slack|%{asterisk}Channel notifications%{asterisk}"),
            asterisk: '*'
          )
        )
      end

      def section_notifications
        section(
          format(
            s_("Slack|To start using notifications, " \
               "%{startMarkup}enable the GitLab for Slack app integration%{endMarkup} in your project settings."),
            startMarkup: "<#{help_page_url('user/project/integrations/gitlab_slack_application.md',
              anchor: 'install-the-gitlab-for-slack-app')}|",
            endMarkup: ">"
          )
        )
      end

      def section_slash_commands_heading
        section(
          format(
            s_("Slack|%{asterisk}Slash commands%{asterisk}"),
            asterisk: '*'
          )
        )
      end

      def section_slash_commands
        section(
          format(
            s_("Slack|Control GitLab from Slack with " \
               "%{startMarkup}slash commands%{endMarkup}. For a list of available commands, enter %{command}."),
            startMarkup: "<#{help_page_url('user/project/integrations/gitlab_slack_application.md',
              anchor: 'slash-commands')}|",
            endMarkup: ">",
            command: "`/gitlab help`"
          )
        )
      end

      def section_slash_commands_connect
        section(
          s_("Slack|To start using slash commands, connect your GitLab account.")
        )
      end

      def section_connect_gitlab_account
        if slack_gitlab_user_connection.present?
          section_gitlab_account_connected
        else
          actions_gitlab_account_not_connected
        end
      end

      def section_gitlab_account_connected
        user = slack_gitlab_user_connection.user

        section(
          format(
            s_("Slack|%{emoji}Connected to GitLab account %{account}."),
            emoji: '✅ ',
            account: "<#{Gitlab::UrlBuilder.build(user)}|#{user.to_reference}>"
          )
        )
      end

      def actions_gitlab_account_not_connected
        account_connection_url = ChatNames::AuthorizeUserService.new(
          {
            team_id: slack_workspace_id,
            user_id: slack_user_id,
            team_domain: slack_workspace_id,
            user_name: 'Slack'
          }
        ).execute

        {
          type: "actions",
          elements: [
            {
              type: "button",
              text: {
                type: "plain_text",
                text: s_("Slack|Connect your GitLab account"),
                emoji: true
              },
              style: "primary",
              url: account_connection_url
            }
          ]
        }
      end

      def section(text)
        {
          type: "section",
          text: {
            type: "mrkdwn",
            text: text
          }
        }
      end
    end
  end
end

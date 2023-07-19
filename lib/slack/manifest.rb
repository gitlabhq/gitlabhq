# frozen_string_literal: true

module Slack
  module Manifest
    class << self
      delegate :to_json, to: :to_h

      def share_url
        "https://api.slack.com/apps?new_app=1&manifest_json=#{ERB::Util.url_encode(to_json)}"
      end

      def to_h
        {
          display_information: display_information,
          features: features,
          oauth_config: oauth_config,
          settings: settings
        }
      end

      private

      def display_information
        {
          name: "GitLab (#{Gitlab.config.gitlab.host.first(26)})",
          description: s_('SlackIntegration|Interact with GitLab without leaving your Slack workspace!'),
          background_color: '#171321',
          # Each element in this array will become a paragraph joined with `\r\n\r\n'.
          long_description: [
            format(
              s_(
                'SlackIntegration|Generated for %{host} by GitLab %{version}.'
              ),
              host: Gitlab.config.gitlab.host,
              version: Gitlab::VERSION
            ),
            s_(
              'SlackIntegration|- *Notifications:* Get notifications to your team\'s Slack channel about events ' \
              'happening inside your GitLab projects.'
            ),
            format(
              s_(
                'SlackIntegration|- *Slash commands:* Quickly open, access, or close issues from Slack using the ' \
                '`%{slash_command}` command. Streamline your GitLab deployments with ChatOps.'
              ),
              slash_command: '/gitlab'
            )
          ].join("\r\n\r\n")
        }
      end

      def features
        {
          app_home: {
            home_tab_enabled: true,
            messages_tab_enabled: false,
            messages_tab_read_only_enabled: true
          },
          bot_user: {
            display_name: 'GitLab',
            always_online: true
          },
          slash_commands: [
            {
              command: '/gitlab',
              url: api_v4('slack/trigger'),
              description: s_('SlackIntegration|GitLab slash commands'),
              usage_hint: s_('SlackIntegration|your-project-name-or-alias command'),
              should_escape: false
            }
          ]
        }
      end

      def oauth_config
        {
          redirect_urls: [
            Gitlab.config.gitlab.url
          ],
          scopes: {
            bot: %w[
              commands
              chat:write
              chat:write.public
            ]
          }
        }
      end

      def settings
        {
          event_subscriptions: {
            request_url: api_v4('integrations/slack/events'),
            bot_events: %w[
              app_home_opened
            ]
          },
          interactivity: {
            is_enabled: true,
            request_url: api_v4('integrations/slack/interactions'),
            message_menu_options_url: api_v4('integrations/slack/options')
          },
          org_deploy_enabled: false,
          socket_mode_enabled: false,
          token_rotation_enabled: false
        }
      end

      def api_v4(path)
        "#{Gitlab.config.gitlab.url}/api/v4/#{path}"
      end
    end
  end
end

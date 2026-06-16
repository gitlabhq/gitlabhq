# frozen_string_literal: true

module Slack
  module Manifest
    BASE_BOT_EVENTS = %w[app_home_opened].freeze
    DUO_BOT_EVENTS = %w[app_mention].freeze

    class << self
      def share_url(duo_enabled: false)
        "https://api.slack.com/apps?new_app=1&manifest_json=#{ERB::Util.url_encode(to_json(duo_enabled: duo_enabled))}"
      end

      def to_json(duo_enabled: false)
        to_h(duo_enabled: duo_enabled).to_json
      end

      def to_h(duo_enabled: false)
        {
          display_information: display_information,
          features: features,
          oauth_config: oauth_config(duo_enabled: duo_enabled),
          settings: settings(duo_enabled: duo_enabled)
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

      def oauth_config(duo_enabled:)
        {
          redirect_urls: [
            Gitlab.config.gitlab.url
          ],
          scopes: {
            bot: SlackIntegration.scopes_for(duo_enabled: duo_enabled)
          }
        }
      end

      def settings(duo_enabled:)
        bot_events = BASE_BOT_EVENTS.dup
        bot_events += DUO_BOT_EVENTS if duo_enabled

        {
          event_subscriptions: {
            request_url: api_v4('integrations/slack/events'),
            bot_events: bot_events
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

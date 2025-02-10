# frozen_string_literal: true

require "discordrb/webhooks"

module Integrations
  module Base
    module Discord
      extend ActiveSupport::Concern

      ATTACHMENT_REGEX = Gitlab::UntrustedRegexp.new(': (?<entry>[^\n]*)\n - (?<name>[^\n]*)\n*')

      include Integrations::Base::ChatNotification

      class_methods do
        def title
          s_("DiscordService|Discord Notifications")
        end

        def description
          s_("DiscordService|Send notifications about project events to a Discord channel.")
        end

        def help
          build_help_page_url(
            'user/project/integrations/discord_notifications.md',
            s_("DiscordService|Send notifications about project events to a Discord channel."),
            _('How do I set up this integration?')
          )
        end

        def to_param
          "discord"
        end

        def supported_events
          %w[push issue confidential_issue merge_request note confidential_note tag_push pipeline wiki_page deployment]
        end
      end

      included do
        field :webhook,
          section: Integrations::Base::Integration::SECTION_TYPE_CONNECTION,
          description: -> { _('Discord webhook (for example, `https://discord.com/api/webhooks/…`).') },
          help: 'e.g. https://discord.com/api/webhooks/…',
          required: true

        field :notify_only_broken_pipelines,
          type: :checkbox,
          section: Integrations::Base::Integration::SECTION_TYPE_CONFIGURATION,
          description: -> { _('Send notifications for broken pipelines.') }

        field :branches_to_be_notified,
          type: :select,
          section: Integrations::Base::Integration::SECTION_TYPE_CONFIGURATION,
          title: -> { s_('Integrations|Branches for which notifications are to be sent') },
          description: -> do
            _('Branches to send notifications for. Valid options are `all`, `default`, ' \
              '`protected`, and `default_and_protected`. The default value is `default`.')
          end,
          choices: -> { branch_choices }

        override :supported_events
        def supported_events
          additional = group_level? ? %w[group_mention group_confidential_mention] : []

          (self.class.supported_events + additional).freeze
        end

        private

        def notify(message, opts)
          webhook_url = opts[:channel]&.first || webhook
          client = Discordrb::Webhooks::Client.new(url: webhook_url)

          client.execute do |builder|
            builder.add_embed do |embed|
              embed.author = Discordrb::Webhooks::EmbedAuthor.new(
                name: message.user_name,
                icon_url: message.user_avatar
              )
              embed.description = "#{message.pretext}\n#{Array.wrap(message.attachments).join("\n")}"

              if ATTACHMENT_REGEX.match?(embed.description)
                embed.description = ATTACHMENT_REGEX.replace_gsub(embed.description) do |match|
                  " #{match[:entry]} - #{match[:name]}\n"
                end
              end

              embed.colour = embed_color(message)
              embed.timestamp = Time.now.utc
            end
          end
        rescue RestClient::Exception => e
          log_error(e.message)
          false
        end
      end

      def default_channel_placeholder
        s_('DiscordService|Override the default webhook (e.g. https://discord.com/api/webhooks/…)')
      end

      def configurable_channels?
        true
      end

      def channel_limit_per_event
        1
      end

      def mask_configurable_channels?
        true
      end

      private

      COLOR_OVERRIDES = {
        'good' => '#0d532a',
        'warning' => '#703800',
        'danger' => '#8d1300'
      }.freeze

      def embed_color(message)
        return 'fc6d26'.hex unless message.respond_to?(:attachment_color)

        color = message.attachment_color

        color = COLOR_OVERRIDES[color] if COLOR_OVERRIDES.key?(color)

        color = color.delete_prefix('#')

        normalize_color(color).hex
      end

      # Expands the short notation to the full colorcode notation
      # 123456 -> 123456
      # 123    -> 112233
      def normalize_color(color)
        return (color[0, 1] * 2) + (color[1, 1] * 2) + (color[2, 1] * 2) if color.length == 3

        color
      end

      def custom_data(data)
        super.merge(markdown: true)
      end
    end
  end
end

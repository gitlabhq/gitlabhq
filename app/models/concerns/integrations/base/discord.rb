# frozen_string_literal: true

module Integrations
  module Base
    module Discord
      extend ActiveSupport::Concern

      include Integrations::Base::ChatNotification

      ATTACHMENT_REGEX = Gitlab::UntrustedRegexp.new(': (?<entry>[^\n]*)\n - (?<name>[^\n]*)\n*')
      DISCORD_URI_REGEX = %r{\Ahttps://discord\.com(/.*)?\z}
      WEBHOOK_ADDRESSABLE_URL_OPTIONS = { schemes: %w[https] }.freeze
      SUPPORTED_EVENTS = %w[
        push
        issue
        confidential_issue
        merge_request
        note
        confidential_note
        tag_push
        pipeline
        wiki_page
        deployment
      ].freeze
      GROUP_SUPPORTED_EVENTS = %w[group_mention group_confidential_mention].freeze
      ALL_SUPPORTED_EVENTS = (SUPPORTED_EVENTS | GROUP_SUPPORTED_EVENTS).freeze

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
            link_text: _('How do I set up this integration?')
          )
        end

        def to_param
          "discord"
        end

        def supported_events
          SUPPORTED_EVENTS
        end

        def all_channel_fields
          ALL_SUPPORTED_EVENTS.map { |event| event_channel_name(event) }
        end

        def has_public_url_validation_options?
          true
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

        validates :webhook,
          format: {
            with: DISCORD_URI_REGEX,
            message: ->(_object, _data) { s_('Integrations|URL must point to discord.com') }
          },
          public_url: WEBHOOK_ADDRESSABLE_URL_OPTIONS, if: :validate_discord_url_field?

        all_channel_fields.each do |channel_field|
          validates channel_field,
            format: {
              with: DISCORD_URI_REGEX,
              message: ->(_object, _data) { s_('Integrations|URL must point to discord.com') }
            },
            public_url: WEBHOOK_ADDRESSABLE_URL_OPTIONS, if: ->(integration) do
              integration.validate_discord_url_field?(channel_field)
            end
        end

        override :supported_events
        def supported_events
          additional = group_level? ? GROUP_SUPPORTED_EVENTS : []

          (self.class.supported_events + additional).freeze
        end

        private

        def notify(message, opts)
          webhook_url = opts[:channel]&.first || webhook

          payload = {
            content: '',
            embeds: Array.wrap(build_embed(message))
          }

          response = Gitlab::HTTP.post(
            webhook_url,
            headers: { 'Content-Type' => 'application/json' },
            body: Gitlab::Json.dump(payload)
          )

          return response if response.success?

          log_error('Error notifying Discord',
            response_body: response.body,
            response_code: response.code
          )
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

      # Prevents breaking changes for users with existing, active, and invalid discord webhooks or event
      # webhook override URLs that were otherwise working for the user. This validation does not run on blank
      # URL fields because presence validation will be done via the `required: true` on each field.
      def validate_discord_url_field?(url_field = 'webhook')
        return false unless activated?
        return false unless properties[url_field.to_s].present?
        return true if active_changed?(to: true)

        # rubocop:disable GitlabSecurity/PublicSend -- url_field must be a field defined on the class, verified by accessing properties
        url_was = public_send(:"#{url_field}_was")
        url_changed = public_send(:"#{url_field}_changed?")
        # rubocop:enable GitlabSecurity/PublicSend

        return false unless url_changed
        return true if url_was.blank?

        url_was.match?(DISCORD_URI_REGEX)
      end

      private

      def build_embed(message)
        embed = {
          color: embed_color(message),
          timestamp: Time.now.utc.iso8601,
          author: {
            name: message.user_name,
            icon_url: message.user_avatar
          }
        }

        description = "#{message.pretext}\n#{Array.wrap(message.attachments).join("\n")}"

        if ATTACHMENT_REGEX.match?(description)
          description = ATTACHMENT_REGEX.replace_gsub(description) do |match|
            " #{match[:entry]} - #{match[:name]}\n"
          end
        end

        embed.merge(description: description)
      end

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

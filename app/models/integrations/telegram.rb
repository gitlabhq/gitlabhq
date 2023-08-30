# frozen_string_literal: true

module Integrations
  class Telegram < BaseChatNotification
    TELEGRAM_HOSTNAME = "https://api.telegram.org/bot%{token}/sendMessage"

    field :token,
      section: SECTION_TYPE_CONNECTION,
      help: -> { s_('TelegramIntegration|Unique authentication token.') },
      non_empty_password_title: -> { s_('TelegramIntegration|New token') },
      non_empty_password_help: -> { s_('TelegramIntegration|Leave blank to use your current token.') },
      placeholder: '123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11',
      exposes_secrets: true,
      is_secret: true,
      required: true

    field :room,
      title: 'Channel identifier',
      section: SECTION_TYPE_CONFIGURATION,
      help: "Unique identifier for the target chat or the username of the target channel (format: @channelusername)",
      placeholder: '@channelusername',
      required: true

    with_options if: :activated? do
      validates :token, :room, presence: true
    end

    before_validation :set_webhook

    def title
      'Telegram'
    end

    def description
      s_("TelegramIntegration|Send notifications about project events to Telegram.")
    end

    def self.to_param
      'telegram'
    end

    def help
      docs_link = ActionController::Base.helpers.link_to(
        _('Learn more.'),
        Rails.application.routes.url_helpers.help_page_url('user/project/integrations/telegram'),
        target: '_blank',
        rel: 'noopener noreferrer'
      )
      format(s_("TelegramIntegration|Send notifications about project events to Telegram. %{docs_link}"),
        docs_link: docs_link.html_safe
      )
    end

    def self.supported_events
      super - ['deployment']
    end

    def sections
      [
        {
          type: SECTION_TYPE_CONNECTION,
          title: s_('Integrations|Connection details'),
          description: help
        },
        {
          type: SECTION_TYPE_TRIGGER,
          title: s_('Integrations|Trigger'),
          description: s_('Integrations|An event will be triggered when one of the following items happen.')
        },
        {
          type: SECTION_TYPE_CONFIGURATION,
          title: s_('Integrations|Notification settings'),
          description: s_('Integrations|Configure the scope of notifications.')
        }
      ]
    end

    private

    def set_webhook
      self.webhook = format(TELEGRAM_HOSTNAME, token: token) if token.present?
    end

    def notify(message, _opts)
      body = {
        text: message.summary,
        chat_id: room,
        parse_mode: 'markdown'
      }

      header = { 'Content-Type' => 'application/json' }
      response = Gitlab::HTTP.post(webhook, headers: header, body: Gitlab::Json.dump(body))

      response if response.success?
    end

    def custom_data(data)
      super(data).merge(markdown: true)
    end
  end
end

# frozen_string_literal: true

module Integrations
  class Telegram < BaseChatNotification
    include HasAvatar
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

    field :thread,
      title: 'Message thread ID',
      section: SECTION_TYPE_CONFIGURATION,
      help: 'Unique identifier for the target message thread (topic in a forum supergroup)',
      placeholder: '123',
      required: false

    field :notify_only_broken_pipelines,
      type: :checkbox,
      section: SECTION_TYPE_CONFIGURATION,
      help: 'If selected, successful pipelines do not trigger a notification event.'

    field :branches_to_be_notified,
      type: :select,
      section: SECTION_TYPE_CONFIGURATION,
      title: -> { s_('Integrations|Branches for which notifications are to be sent') },
      choices: -> { branch_choices }

    with_options if: :activated? do
      validates :token, :room, presence: true
      validates :thread, numericality: { only_integer: true }, allow_blank: true
    end

    before_validation :set_webhook

    def self.title
      'Telegram'
    end

    def self.description
      s_("TelegramIntegration|Send notifications about project events to Telegram.")
    end

    def self.to_param
      'telegram'
    end

    def self.help
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

    private

    def set_webhook
      self.webhook = format(TELEGRAM_HOSTNAME, token: token) if token.present?
    end

    def notify(message, _opts)
      body = {
        text: message.summary,
        chat_id: room,
        message_thread_id: thread,
        parse_mode: 'markdown'
      }.compact_blank

      header = { 'Content-Type' => 'application/json' }
      response = Gitlab::HTTP.post(webhook, headers: header, body: Gitlab::Json.dump(body))

      # We're retrying the request with a different format to ensure accurate formatting and
      # avoid receiving a 400 response due to invalid markdown.
      if response.bad_request?
        body.except!(:parse_mode)
        response = Gitlab::HTTP.post(webhook, headers: header, body: Gitlab::Json.dump(body))
      end

      response if response.success?
    end

    def custom_data(data)
      super(data).merge(markdown: true)
    end
  end
end

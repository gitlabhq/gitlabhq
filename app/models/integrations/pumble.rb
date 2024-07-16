# frozen_string_literal: true

module Integrations
  class Pumble < BaseChatNotification
    include HasAvatar

    field :webhook,
      section: SECTION_TYPE_CONNECTION,
      help: 'https://api.pumble.com/workspaces/x/...',
      required: true

    field :notify_only_broken_pipelines,
      type: :checkbox,
      section: SECTION_TYPE_CONFIGURATION,
      help: 'If selected, successful pipelines do not trigger a notification event.'

    field :branches_to_be_notified,
      type: :select,
      section: SECTION_TYPE_CONFIGURATION,
      title: -> { s_('Integrations|Branches for which notifications are to be sent') },
      choices: -> { branch_choices }

    def self.title
      'Pumble'
    end

    def self.description
      s_("PumbleIntegration|Send notifications about project events to Pumble.")
    end

    def self.to_param
      'pumble'
    end

    def self.help
      docs_link = ActionController::Base.helpers.link_to(
        _('Learn more.'),
        Rails.application.routes.url_helpers.help_page_url('user/project/integrations/pumble'),
        target: '_blank',
        rel: 'noopener noreferrer'
      )
      # rubocop:disable Layout/LineLength
      s_("PumbleIntegration|Send notifications about project events to Pumble. %{docs_link}") % { docs_link: docs_link.html_safe }
      # rubocop:enable Layout/LineLength
    end

    def default_channel_placeholder
    end

    def self.supported_events
      %w[push issue confidential_issue merge_request note confidential_note tag_push
        pipeline wiki_page]
    end

    private

    def notify(message, opts)
      header = { 'Content-Type' => 'application/json' }
      response = Gitlab::HTTP.post(webhook, headers: header, body: Gitlab::Json.dump({ text: message.summary }))

      response if response.success?
    end
  end
end

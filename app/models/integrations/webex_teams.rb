# frozen_string_literal: true

module Integrations
  class WebexTeams < BaseChatNotification
    field :webhook,
      section: SECTION_TYPE_CONNECTION,
      help: 'https://api.ciscospark.com/v1/webhooks/incoming/...',
      description: 'The Webex Teams webhook. For example, https://api.ciscospark.com/v1/webhooks/incoming/...',
      required: true

    field :notify_only_broken_pipelines,
      type: :checkbox,
      section: SECTION_TYPE_CONFIGURATION,
      description: -> { _('Send notifications for broken pipelines.') }

    field :branches_to_be_notified,
      type: :select,
      section: SECTION_TYPE_CONFIGURATION,
      title: -> { s_('Integrations|Branches for which notifications are to be sent') },
      description: -> { _('Branches to send notifications for. Valid options are `all`, `default`, `protected`, and `default_and_protected`. The default value is `default`.') },
      choices: -> { branch_choices }

    def self.title
      s_("WebexTeamsService|Webex Teams")
    end

    def self.description
      s_("WebexTeamsService|Send notifications about project events to Webex Teams.")
    end

    def self.to_param
      'webex_teams'
    end

    def self.help
      docs_link = ActionController::Base.helpers.link_to _('Learn more.'), Rails.application.routes.url_helpers.help_page_url('user/project/integrations/webex_teams'), target: '_blank', rel: 'noopener noreferrer'
      s_("WebexTeamsService|Send notifications about project events to a Webex Teams conversation. %{docs_link}") % { docs_link: docs_link.html_safe }
    end

    def default_channel_placeholder
    end

    def self.supported_events
      %w[push issue confidential_issue merge_request note confidential_note tag_push pipeline wiki_page]
    end

    private

    def notify(message, opts)
      header = { 'Content-Type' => 'application/json' }
      response = Gitlab::HTTP.post(webhook, headers: header, body: Gitlab::Json.dump({ markdown: message.summary }))

      response if response.success?
    end

    def custom_data(data)
      super(data).merge(markdown: true)
    end
  end
end

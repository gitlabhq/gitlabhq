# frozen_string_literal: true

module Integrations
  class UnifyCircuit < BaseChatNotification
    field :webhook,
      section: SECTION_TYPE_CONNECTION,
      help: 'https://yourcircuit.com/rest/v2/webhooks/incoming/…',
      required: true

    field :notify_only_broken_pipelines,
      type: :checkbox,
      section: SECTION_TYPE_CONFIGURATION

    field :branches_to_be_notified,
      type: :select,
      section: SECTION_TYPE_CONFIGURATION,
      title: -> { s_('Integrations|Branches for which notifications are to be sent') },
      choices: -> { branch_choices }

    def self.title
      'Unify Circuit'
    end

    def self.description
      s_('Integrations|Send notifications about project events to Unify Circuit.')
    end

    def self.to_param
      'unify_circuit'
    end

    def self.help
      docs_link = ActionController::Base.helpers.link_to _('How do I set up this service?'), Rails.application.routes.url_helpers.help_page_url('user/project/integrations/unify_circuit'), target: '_blank', rel: 'noopener noreferrer'
      s_('Integrations|Send notifications about project events to a Unify Circuit conversation. %{docs_link}').html_safe % { docs_link: docs_link.html_safe }
    end

    def default_channel_placeholder
    end

    def self.supported_events
      %w[push issue confidential_issue merge_request note confidential_note tag_push
        pipeline wiki_page]
    end

    private

    def notify(message, opts)
      body = {
        subject: message.project_name,
        text: message.summary,
        markdown: true
      }

      response = Gitlab::HTTP.post(webhook, body: Gitlab::Json.dump(body))

      response if response.success?
    end

    def custom_data(data)
      super(data).merge(markdown: true)
    end
  end
end

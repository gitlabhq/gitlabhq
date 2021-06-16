# frozen_string_literal: true

module Integrations
  class UnifyCircuit < BaseChatNotification
    def title
      'Unify Circuit'
    end

    def description
      s_('Integrations|Send notifications about project events to Unify Circuit.')
    end

    def self.to_param
      'unify_circuit'
    end

    def help
      'This service sends notifications about projects events to a Unify Circuit conversation.<br />
      To set up this service:
      <ol>
        <li><a href="https://www.circuit.com/unifyportalfaqdetail?articleId=164448">Set up an incoming webhook for your conversation</a>. All notifications will come to this conversation.</li>
        <li>Paste the <strong>Webhook URL</strong> into the field below.</li>
        <li>Select events below to enable notifications.</li>
      </ol>'
    end

    def event_field(event)
    end

    def default_channel_placeholder
    end

    def self.supported_events
      %w[push issue confidential_issue merge_request note confidential_note tag_push
         pipeline wiki_page]
    end

    def default_fields
      [
        { type: 'text', name: 'webhook', placeholder: "e.g. https://circuit.com/rest/v2/webhooks/incoming/…", required: true },
        { type: 'checkbox', name: 'notify_only_broken_pipelines' },
        { type: 'select', name: 'branches_to_be_notified', choices: branch_choices }
      ]
    end

    private

    def notify(message, opts)
      response = Gitlab::HTTP.post(webhook, body: {
        subject: message.project_name,
        text: message.summary,
        markdown: true
      }.to_json)

      response if response.success?
    end

    def custom_data(data)
      super(data).merge(markdown: true)
    end
  end
end

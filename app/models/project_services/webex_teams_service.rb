# frozen_string_literal: true

class WebexTeamsService < ChatNotificationService
  def title
    'Webex Teams'
  end

  def description
    'Receive event notifications in Webex Teams'
  end

  def self.to_param
    'webex_teams'
  end

  def help
    'This service sends notifications about projects events to a Webex Teams conversation.<br />
    To set up this service:
    <ol>
      <li><a href="https://apphub.webex.com/teams/applications/incoming-webhooks-cisco-systems">Set up an incoming webhook for your conversation</a>. All notifications will come to this conversation.</li>
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
      { type: 'text', name: 'webhook', placeholder: "e.g. https://api.ciscospark.com/v1/webhooks/incoming/…", required: true },
      { type: 'checkbox', name: 'notify_only_broken_pipelines' },
      { type: 'select', name: 'branches_to_be_notified', choices: branch_choices }
    ]
  end

  private

  def notify(message, opts)
    header = { 'Content-Type' => 'application/json' }
    response = Gitlab::HTTP.post(webhook, headers: header, body: { markdown: message.pretext }.to_json)

    response if response.success?
  end

  def custom_data(data)
    super(data).merge(markdown: true)
  end
end

class MicrosoftTeamsService < ChatNotificationService
  def title
    'Microsoft Teams Notification'
  end

  def description
    'Receive event notifications in Microsoft Team'
  end

  def self.to_param
    'microsoft_teams'
  end

  #TODO: Setup the description accordingly
  def help
    'This service sends notifications about projects events to Microsoft Teams channels.<br />
    To set up this service:
    <ol>
      <li><a href="https://msdn.microsoft.com/en-us/microsoft-teams/connectors">Getting started with 365 Office Connectors For Microsoft Teams</a>.</li>
      <li>Paste the <strong>Webhook URL</strong> into the field below.</li>
      <li>Select events below to enable notifications.</li>
    </ol>'
  end

  def default_channel_placeholder
    "Channel name (e.g. general)"
  end

  def webhook_placeholder
    'https://outlook.office.com/webhook/…'
  end

  def event_field(event)
  end

  def default_fields
    [
      { type: 'text', name: 'webhook', placeholder: "e.g. #{webhook_placeholder}" },
      { type: 'checkbox', name: 'notify_only_broken_pipelines' },
      { type: 'checkbox', name: 'notify_only_default_branch' },
    ]
  end

  def execute(data)
    return unless supported_events.include?(data[:object_kind])
    return unless webhook.present?

    object_kind = data[:object_kind]

    data = data.merge(
      project_url: project_url,
      project_name: project_name,
      format: false
    )

    message = get_message(object_kind, data)

    return false unless message

    MicrosoftTeams::Notifier.new(webhook).ping({
      title: message.project_name,
      activity: message.activity,
      attachments: message.attachments,
    })
  end
end

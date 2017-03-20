class MattermostService < ChatNotificationService
  def title
    'Mattermost notifications'
  end

  def description
    'Receive event notifications in Mattermost'
  end

  def self.to_param
    'mattermost'
  end

  def help
    'This service sends notifications about projects events to Mattermost channels.<br />
    To set up this service:
    <ol>
      <li><a href="https://docs.mattermost.com/developer/webhooks-incoming.html#enabling-incoming-webhooks">Enable incoming webhooks</a> in your Mattermost installation.</li>
      <li><a href="https://docs.mattermost.com/developer/webhooks-incoming.html#creating-integrations-using-incoming-webhooks">Add an incoming webhook</a> in your Mattermost team. The default channel can be overridden for each event.</li>
      <li>Paste the webhook <strong>URL</strong> into the field below.</li>
      <li>Select events below to enable notifications. The <strong>Channel handle</strong> and <strong>Username</strong> fields are optional.</li>
    </ol>'
  end

  def fields
    default_fields + build_event_channels
  end

  def default_fields
    [
      { type: 'text', name: 'webhook', placeholder: 'e.g. http://mattermost_host/hooks/…' },
      { type: 'text', name: 'username', placeholder: 'e.g. GitLab' },
      { type: 'checkbox', name: 'notify_only_broken_pipelines' },
    ]
  end

  def default_channel_placeholder
    "Channel handle (e.g. town-square)"
  end
end

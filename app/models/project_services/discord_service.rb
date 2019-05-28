# frozen_string_literal: true

require "discordrb/webhooks"

class DiscordService < ChatNotificationService
  def title
    s_("DiscordService|Discord Notifications")
  end

  def description
    s_("DiscordService|Receive event notifications in Discord")
  end

  def self.to_param
    "discord"
  end

  def help
    "This service sends notifications about project events to Discord channels.<br />
    To set up this service:
    <ol>
      <li><a href='https://support.discordapp.com/hc/en-us/articles/228383668-Intro-to-Webhooks'>Setup a custom Incoming Webhook</a>.</li>
      <li>Paste the <strong>Webhook URL</strong> into the field below.</li>
      <li>Select events below to enable notifications.</li>
    </ol>"
  end

  def event_field(event)
    # No-op.
  end

  def default_channel_placeholder
    # No-op.
  end

  def self.supported_events
    %w[push issue confidential_issue merge_request note confidential_note tag_push
       pipeline wiki_page]
  end

  def default_fields
    [
      { type: "text", name: "webhook", placeholder: "e.g. https://discordapp.com/api/webhooks/…" },
      { type: "checkbox", name: "notify_only_broken_pipelines" },
      { type: "checkbox", name: "notify_only_default_branch" }
    ]
  end

  private

  def notify(message, opts)
    client = Discordrb::Webhooks::Client.new(url: webhook)

    client.execute do |builder|
      builder.content = message.pretext
    end
  end

  def custom_data(data)
    super(data).merge(markdown: true)
  end
end

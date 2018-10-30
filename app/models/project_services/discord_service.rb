# frozen_string_literal: true

require "discordrb/webhooks"

class DiscordService < ChatNotificationService
  def title
    "Discord Notifications"
  end

  def description
    "Receive event notifications in Discord"
  end

  def self.to_param
    "discord"
  end

  def help
    "This service sends notifications about projects events to Discord channels.<br />
    To set up this service:
    <ol>
      <li><a href='ADD-DISCORD-LINK-HERE'>Setup a custom Incoming Webhook</a>.</li>
      <li>Paste the <strong>Webhook URL</strong> into the field below.</li>
      <li>Select events below to enable notifications.</li>
    </ol>"
  end

  def webhook_placeholder
    "https://discordapp.com/api/webhooks/..."
  end

  def event_field(event)
  end

  def default_channel_placeholder
  end

  def default_fields
    [
      { type: "text", name: "webhook", placeholder: "e.g. #{webhook_placeholder}" },
      { type: "checkbox", name: "notify_only_broken_pipelines" },
      { type: "checkbox", name: "notify_only_default_branch" }
    ]
  end

  private

  def notify(message, opts)
    client = Discordrb::Webhooks::Client.new(url: webhook)
    client.execute do |builder|
      builder.content = message.pretext
      # builder.add_embed do |embed|
      #   embed.title = 'Embed title'
      #   embed.description = 'Embed description'
      #   embed.timestamp = Time.now
      # end
    end
  end

  def custom_data(data)
    super(data).merge(markdown: true)
  end
end

# frozen_string_literal: true

require "discordrb/webhooks"

class DiscordService < ChatNotificationService
  ATTACHMENT_REGEX = /: (?<entry>.*?)\n - (?<name>.*)\n*/.freeze

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
      { type: 'select', name: 'branches_to_be_notified', choices: branch_choices }
    ]
  end

  private

  def notify(message, opts)
    client = Discordrb::Webhooks::Client.new(url: webhook)

    client.execute do |builder|
      builder.add_embed do |embed|
        embed.author = Discordrb::Webhooks::EmbedAuthor.new(name: message.user_name, icon_url: message.user_avatar)
        embed.description = (message.pretext + "\n" + Array.wrap(message.attachments).join("\n")).gsub(ATTACHMENT_REGEX, " \\k<entry> - \\k<name>\n")
      end
    end
  end

  def custom_data(data)
    super(data).merge(markdown: true)
  end
end

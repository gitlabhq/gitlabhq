# frozen_string_literal: true

require 'hangouts_chat'

class HangoutsChatService < ChatNotificationService
  def title
    'Hangouts Chat'
  end

  def description
    'Receive event notifications in Google Hangouts Chat'
  end

  def self.to_param
    'hangouts_chat'
  end

  def help
    'This service sends notifications about projects events to Google Hangouts Chat room.<br />
    To set up this service:
    <ol>
      <li><a href="https://developers.google.com/hangouts/chat/how-tos/webhooks">Set up an incoming webhook for your room</a>. All notifications will come to this room.</li>
      <li>Paste the <strong>Webhook URL</strong> into the field below.</li>
      <li>Select events below to enable notifications.</li>
    </ol>'
  end

  def event_field(event)
  end

  def default_channel_placeholder
  end

  def webhook_placeholder
    'https://chat.googleapis.com/v1/spaces…'
  end

  def default_fields
    [
      { type: 'text', name: 'webhook', placeholder: "e.g. #{webhook_placeholder}" },
      { type: 'checkbox', name: 'notify_only_broken_pipelines' },
      { type: 'checkbox', name: 'notify_only_default_branch' }
    ]
  end

  private

  def notify(message, opts)
    simple_text = parse_simple_text_message(message)
    HangoutsChat::Sender.new(webhook).simple(simple_text)
  end

  def parse_simple_text_message(message)
    header = message.pretext
    return header if message.attachments.empty?

    attachment = message.attachments.first
    title      = format_attachment_title(attachment)
    body       = attachment[:text]

    [header, title, body].compact.join("\n")
  end

  def format_attachment_title(attachment)
    return attachment[:title] unless attachment[:title_link]

    "<#{attachment[:title_link]}|#{attachment[:title]}>"
  end
end

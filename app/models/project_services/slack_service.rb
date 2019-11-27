# frozen_string_literal: true

class SlackService < ChatNotificationService
  def title
    'Slack notifications'
  end

  def description
    'Receive event notifications in Slack'
  end

  def self.to_param
    'slack'
  end

  def help
    'This service sends notifications about projects events to Slack channels.<br />
    To set up this service:
    <ol>
      <li><a href="https://slack.com/apps/A0F7XDUAZ-incoming-webhooks">Add an incoming webhook</a> in your Slack team. The default channel can be overridden for each event.</li>
      <li>Paste the <strong>Webhook URL</strong> into the field below.</li>
      <li>Select events below to enable notifications. The <strong>Channel name</strong> and <strong>Username</strong> fields are optional.</li>
    </ol>'
  end

  def default_channel_placeholder
    "Channel name (e.g. general)"
  end

  def webhook_placeholder
    'https://hooks.slack.com/services/…'
  end

  module Notifier
    private

    def notify(message, opts)
      # See https://github.com/stevenosloan/slack-notifier#custom-http-client
      notifier = Slack::Notifier.new(webhook, opts.merge(http_client: HTTPClient))

      notifier.ping(
        message.pretext,
        attachments: message.attachments,
        fallback: message.fallback
      )
    end

    class HTTPClient
      def self.post(uri, params = {})
        params.delete(:http_options) # these are internal to the client and we do not want them
        Gitlab::HTTP.post(uri, body: params)
      end
    end
  end

  include Notifier
end

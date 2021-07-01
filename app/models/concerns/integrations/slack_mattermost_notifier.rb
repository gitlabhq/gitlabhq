# frozen_string_literal: true

module Integrations
  module SlackMattermostNotifier
    private

    def notify(message, opts)
      # See https://gitlab.com/gitlab-org/slack-notifier/#custom-http-client
      notifier = ::Slack::Messenger.new(webhook, opts.merge(http_client: HTTPClient))
      notifier.ping(
        message.pretext,
        attachments: message.attachments,
        fallback: message.fallback
      )
    end

    class HTTPClient
      def self.post(uri, params = {})
        params.delete(:http_options) # these are internal to the client and we do not want them
        Gitlab::HTTP.post(uri, body: params, use_read_total_timeout: true)
      end
    end
  end
end

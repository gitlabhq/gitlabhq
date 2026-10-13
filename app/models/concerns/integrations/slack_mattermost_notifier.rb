# frozen_string_literal: true

module Integrations
  module SlackMattermostNotifier
    private

    def notify(message, opts)
      # See https://gitlab.com/gitlab-org/slack-notifier/#custom-http-client
      #
      # Links are converted while the message is built, so the gem's link formatters are
      # left out: they would turn user-written text into links again. Configuring
      # middleware replaces the whole default stack, hence `at` and `channels` here.
      notifier = ::Slack::Messenger.new(webhook, opts.merge(http_client: HTTPClient)) do
        middleware(at: {}, channels: {})
      end
      responses = notifier.ping(
        message.pretext,
        attachments: message.attachments,
        fallback: message.fallback
      )

      responses.each do |response|
        next if response.success?

        log_error('SlackMattermostNotifier HTTP error response',
          request_host: response.request.uri.host,
          response_code: response.code,
          response_body: response.body
        )
      end
    end

    class HTTPClient
      def self.post(uri, params = {})
        params.delete(:http_options) # these are internal to the client and we do not want them
        Clients::HTTP.post(uri, body: params)
      end
    end
  end
end

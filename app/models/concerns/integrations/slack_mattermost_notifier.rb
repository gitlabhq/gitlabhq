# frozen_string_literal: true

module Integrations
  module SlackMattermostNotifier
    private

    def notify(message, opts)
      # See https://gitlab.com/gitlab-org/slack-notifier/#custom-http-client
      #
      # TODO: By default both Markdown and HTML links are converted into Slack "mrkdwn" syntax,
      # but it seems we only need to support Markdown and could disable HTML.
      #
      # See:
      # - https://gitlab.com/gitlab-org/slack-notifier#middleware
      # - https://gitlab.com/gitlab-org/gitlab/-/issues/347048
      notifier = ::Slack::Messenger.new(webhook, opts.merge(http_client: HTTPClient))
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
        Gitlab::HTTP.post(uri, body: params)
      end
    end
  end
end

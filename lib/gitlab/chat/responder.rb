# frozen_string_literal: true

module Gitlab
  module Chat
    module Responder
      # Returns an instance of the responder to use for generating chat
      # responses.
      #
      # This method will return `nil` if no formatter is available for the given
      # build.
      #
      # build - A `Ci::Build` that executed a chat command.
      def self.responder_for(build)
        response_url = build.pipeline.chat_data&.response_url
        return unless response_url

        if response_url.start_with?('https://hooks.slack.com/')
          Gitlab::Chat::Responder::Slack.new(build)
        else
          Gitlab::Chat::Responder::Mattermost.new(build)
        end
      end
    end
  end
end

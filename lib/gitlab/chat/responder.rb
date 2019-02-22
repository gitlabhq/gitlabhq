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
        service = build.pipeline.chat_data&.chat_name&.service

        if (responder = service.try(:chat_responder))
          responder.new(build)
        end
      end
    end
  end
end

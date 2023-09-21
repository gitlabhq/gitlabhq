# frozen_string_literal: true

module Gitlab
  module Git
    #
    # PreReceiveError is special because its message gets displayed to users
    # in the web UI. Because of this, we:
    # - Only display errors that have been marked as safe with a prefix.
    #   This is to prevent leaking of stacktraces, or other sensitive info.
    # - Sanitize the string of any XSS
    class PreReceiveError < StandardError
      SAFE_MESSAGE_PREFIXES = [
        'GitLab:', # Messages from gitlab-shell
        'GL-HOOK-ERR:' # Messages marked as safe by user
      ].freeze

      SAFE_MESSAGE_REGEX = /^(#{SAFE_MESSAGE_PREFIXES.join('|')})\s*(?<safe_message>.+)/

      attr_reader :raw_message

      def initialize(message = '', fallback_message: '')
        @raw_message = message

        sanitized_msg = sanitize(message)

        if sanitized_msg.present?
          super(sanitized_msg)
        else
          super(fallback_message)
        end
      end

      private

      # In gitaly-ruby we override this method to do nothing, so that
      # sanitization happens in gitlab-rails only.
      def sanitize(message)
        return message if message.blank?

        safe_messages = message.split("\n").map do |msg|
          if (match = msg.match(SAFE_MESSAGE_REGEX))
            match[:safe_message].presence
          end
        end

        safe_messages = safe_messages.compact.join("\n")

        Gitlab::Utils.nlbr(safe_messages)
      end
    end
  end
end

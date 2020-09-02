# frozen_string_literal: true

module Gitlab
  module Git
    class BaseError < StandardError
      DEBUG_ERROR_STRING_REGEX = /(.*?) debug_error_string:.*$/m.freeze

      def initialize(msg = nil)
        if msg
          raw_message = msg.to_s
          match = DEBUG_ERROR_STRING_REGEX.match(raw_message)
          raw_message = match[1] if match

          super(raw_message)
        else
          super
        end
      end
    end
  end
end

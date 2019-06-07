# frozen_string_literal: true

module Gitlab
  module GitAccessResult
    class Success
      attr_reader :console_messages

      def initialize(console_messages: [])
        @console_messages = console_messages
      end
    end
  end
end

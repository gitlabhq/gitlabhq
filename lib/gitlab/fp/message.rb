# frozen_string_literal: true

module Gitlab
  module Fp
    # A message's content can be a hash containing any object that is relevant to the message. It will be
    # used to provide content when the final Result from the chain is pattern matched
    # on the message type and returned to the user.
    # The content is required to be a hash so that it can be destructured and type-checked with
    # rightward assignment.
    class Message
      attr_reader :content

      # @param [Hash] content
      # @return [Message]
      # raise [ArgumentError] if content is not a Hash
      def initialize(content = {})
        raise ArgumentError, 'content must be a Hash' unless content.is_a?(Hash)

        @content = content
      end

      # @param [Gitlab::Fp::Message] other
      # @return [TrueClass, FalseClass]
      def ==(other)
        self.class == other.class && content == other.content
      end
    end
  end
end

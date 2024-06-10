# frozen_string_literal: true

module RemoteDevelopment
  # A message's context can be a hash containing any object that is relevant to the message. It will be
  # used to provide context when the final Result from the chain is pattern matched
  # on the message type and returned to the user.
  # The context is required to be a hash so that it can be destructured and type-checked with
  # rightward assignment.
  class Message
    attr_reader :context

    # @param [Hash] context
    # @return [Message]
    # raise [ArgumentError] if context is not a Hash
    def initialize(context = {})
      raise ArgumentError, 'context must be a Hash' unless context.is_a?(Hash)

      @context = context
    end

    # @param [RemoteDevelopment::Message] other
    # @return [TrueClass, FalseClass]
    def ==(other)
      self.class == other.class && context == other.context
    end
  end
end

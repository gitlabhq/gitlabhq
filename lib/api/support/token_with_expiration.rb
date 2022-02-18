# frozen_string_literal: true

module API
  module Support
    class TokenWithExpiration
      def initialize(strategy, instance)
        @strategy = strategy
        @instance = instance
      end

      def token
        @strategy.get_token(@instance)
      end

      def token_expires_at
        @strategy.expires_at(@instance)
      end

      def expirable?
        @strategy.expirable?
      end
    end
  end
end

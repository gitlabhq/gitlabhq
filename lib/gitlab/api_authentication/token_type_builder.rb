# frozen_string_literal: true

# See Gitlab::Auth::AuthBuilder
module Gitlab
  module APIAuthentication
    class TokenTypeBuilder
      def initialize(strategies)
        @strategies = strategies
      end

      def token_types(*resolvers)
        ::Gitlab::APIAuthentication::SentThroughBuilder.new(@strategies, resolvers)
      end

      alias_method :token_type, :token_types
    end
  end
end

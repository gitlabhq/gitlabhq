# frozen_string_literal:true

module Authn
  module Tokens
    class ClusterAgentToken
      def self.prefix?(plaintext)
        plaintext.start_with?(::Clusters::AgentToken::TOKEN_PREFIX)
      end

      attr_reader :revocable, :source

      def initialize(plaintext, source)
        @revocable = ::Clusters::AgentToken.find_by_token(plaintext)
        @source = source
      end

      def present_with
        ::API::Entities::Clusters::AgentToken
      end

      def revoke!(_current_user)
        raise ::Authn::AgnosticTokenIdentifier::NotFoundError, 'Not Found' if revocable.blank?

        raise ::Authn::AgnosticTokenIdentifier::UnsupportedTokenError, 'Unsupported token type'
      end
    end
  end
end

# frozen_string_literal:true

module Authn
  module Tokens
    class ClusterAgentToken
      def self.prefix?(plaintext)
        plaintext.start_with?(::Clusters::AgentToken::TOKEN_PREFIX)
      end

      attr_reader :revocable, :source

      def initialize(plaintext, source)
        return unless self.class.prefix?(plaintext)

        @revocable = ::Clusters::AgentToken.find_by_token(plaintext)
        @source = source
      end

      def present_with
        ::API::Entities::Clusters::AgentToken
      end

      def revoke!(current_user)
        raise ::Authn::AgnosticTokenIdentifier::NotFoundError, 'Not Found' if revocable.blank?

        service = ::Clusters::AgentTokens::RevokeService.new(token: revocable, current_user: current_user)
        service.execute
      end
    end
  end
end

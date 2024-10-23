# frozen_string_literal:true

module Authn
  module Tokens
    class DeployToken
      def self.prefix?(plaintext)
        plaintext.start_with?(::DeployToken::DEPLOY_TOKEN_PREFIX)
      end

      attr_reader :revocable, :source

      def initialize(plaintext, source)
        @revocable = ::DeployToken.find_by_token(plaintext)
        @source = source
      end

      def revoke!(current_user)
        raise ::Authn::AgnosticTokenIdentifier::NotFoundError, 'Not Found' if revocable.blank?

        service = ::Groups::DeployTokens::RevokeService.new(
          revocable.group,
          current_user,
          { id: revocable.id }
        )
        service.source = source
        service.execute
      end
    end
  end
end

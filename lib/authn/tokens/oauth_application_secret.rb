# frozen_string_literal:true

module Authn
  module Tokens
    class OauthApplicationSecret
      def self.prefix?(plaintext)
        prefix =
          ::Gitlab::DoorkeeperSecretStoring::Token::UniqueApplicationToken::OAUTH_APPLICATION_SECRET_PREFIX_FORMAT
          .split('-').first

        plaintext.start_with?(prefix)
      end

      attr_reader :revocable, :source

      def initialize(plaintext, source)
        @revocable = ::Doorkeeper::Application.find_by_plaintext_token(:secret, plaintext)
        @source = source
      end

      def present_with
        ::API::Entities::Application
      end

      def revoke!(_current_user)
        raise ::Authn::AgnosticTokenIdentifier::NotFoundError, 'Not Found' if revocable.blank?

        raise ::Authn::AgnosticTokenIdentifier::UnsupportedTokenError, 'Revocation not supported for this token type'
      end
    end
  end
end

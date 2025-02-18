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

      def revoke!(current_user)
        raise ::Authn::AgnosticTokenIdentifier::NotFoundError, 'Not Found' if revocable.blank?

        Authz::Applications::ResetSecretService.new(
          application: revocable,
          current_user: current_user
        ).execute
      end
    end
  end
end

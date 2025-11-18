# frozen_string_literal:true

module Authn
  module Tokens
    class OauthApplicationSecret
      def self.prefix?(plaintext)
        # Extract the token type prefix from both the default and custom prefix formats. We use uniq to handle the case
        # that the prefix has not been changed and thus prefix_for_oauth_application_secret and
        # OAUTH_APPLICATION_SECRET_PREFIX_FORMAT are the same
        prefixes = [
          ::Gitlab::DoorkeeperSecretStoring::Token::UniqueApplicationToken.prefix_for_oauth_application_secret,
          ::Gitlab::DoorkeeperSecretStoring::Token::UniqueApplicationToken::OAUTH_APPLICATION_SECRET_PREFIX_FORMAT
        ].uniq.map { |prefix_format| prefix_format.delete_suffix('-%{token}') }

        plaintext.start_with?(*prefixes)
      end

      attr_reader :revocable, :source

      def initialize(plaintext, source)
        @revocable = ::Authn::OauthApplication.find_by_plaintext_token(:secret, plaintext)
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

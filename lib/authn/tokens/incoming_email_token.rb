# frozen_string_literal:true

module Authn
  module Tokens
    class IncomingEmailToken
      def self.prefix?(plaintext)
        plaintext.start_with?(::User::INCOMING_MAIL_TOKEN_PREFIX)
      end

      attr_reader :revocable, :source

      def initialize(plaintext, source)
        @revocable = ::User.find_by_incoming_email_token(plaintext)
        @source = source
      end

      def present_with
        ::API::Entities::User
      end

      def revoke!(_current_user)
        raise ::Authn::AgnosticTokenIdentifier::NotFoundError, 'Not Found' if revocable.blank?

        raise ::Authn::AgnosticTokenIdentifier::UnsupportedTokenError, 'Unsupported token type'
      end
    end
  end
end

# frozen_string_literal:true

module Authn
  module Tokens
    class IncomingEmailToken
      def self.prefix?(plaintext)
        incoming_email_token_prefixes = [::User.prefix_for_incoming_mail_token,
          ::User::INCOMING_MAIL_TOKEN_PREFIX].uniq

        plaintext.start_with?(*incoming_email_token_prefixes)
      end

      attr_reader :revocable, :source

      def initialize(plaintext, source)
        @revocable = ::User.find_by_incoming_email_token(plaintext)
        @source = source
      end

      def present_with
        ::API::Entities::User
      end

      def revoke!(current_user)
        raise ::Authn::AgnosticTokenIdentifier::NotFoundError, 'Not Found' if revocable.blank?

        Users::ResetIncomingEmailTokenService.new(current_user: current_user, user: revocable).execute!
      end
    end
  end
end

# frozen_string_literal:true

module Authn
  module Tokens
    class CiTriggerToken
      def self.prefix?(plaintext)
        plaintext.start_with?(::Ci::Trigger::TRIGGER_TOKEN_PREFIX)
      end

      attr_reader :revocable, :source

      def initialize(plaintext, source)
        @revocable = ::Ci::Trigger.find_by_token(plaintext)
        @source = source
      end

      def present_with
        ::API::Entities::Trigger
      end

      def revoke!(_current_user)
        raise ::Authn::AgnosticTokenIdentifier::NotFoundError, 'Not Found' if revocable.blank?

        raise ::Authn::AgnosticTokenIdentifier::UnsupportedTokenError, 'Unsupported token type'
      end
    end
  end
end

# frozen_string_literal:true

module Authn
  module Tokens
    class CiJobToken
      def self.prefix?(plaintext)
        plaintext.start_with?(::Ci::Build::TOKEN_PREFIX)
      end

      attr_reader :revocable, :source

      def initialize(plaintext, source)
        @revocable = ::Ci::AuthJobFinder.new(token: plaintext).execute

        @source = source
      end

      def present_with
        ::API::Entities::Ci::JobToken
      end

      def revoke!(_current_user)
        raise ::Authn::AgnosticTokenIdentifier::NotFoundError, 'Not Found' if revocable.blank?

        raise ::Authn::AgnosticTokenIdentifier::UnsupportedTokenError, 'Unsupported token type'
      end
    end
  end
end

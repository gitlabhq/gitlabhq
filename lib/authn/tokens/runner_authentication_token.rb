# frozen_string_literal:true

module Authn
  module Tokens
    class RunnerAuthenticationToken
      def self.prefix?(plaintext)
        plaintext.start_with?(Ci::Runner::CREATED_RUNNER_TOKEN_PREFIX)
      end

      attr_reader :revocable, :source

      def initialize(plaintext, source)
        @revocable = ::Ci::Runner.find_by_token(plaintext)
        @source = source
      end

      def present_with
        ::API::Entities::Ci::Runner
      end

      def revoke!(_current_user)
        raise ::Authn::AgnosticTokenIdentifier::NotFoundError, 'Not Found' if revocable.blank?

        raise ::Authn::AgnosticTokenIdentifier::UnsupportedTokenError, 'Unsupported token type'
      end
    end
  end
end

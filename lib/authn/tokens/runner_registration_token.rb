# frozen_string_literal:true

module Authn
  module Tokens
    class RunnerRegistrationToken
      def self.prefix?(plaintext)
        plaintext.start_with?(::RunnersTokenPrefixable::RUNNERS_TOKEN_PREFIX)
      end

      attr_reader :revocable, :source

      def initialize(_plaintext, source)
        @revocable = nil
        @source = source
      end
    end
  end
end

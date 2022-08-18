# frozen_string_literal: true

module Users
  module EmailVerification
    class GenerateTokenService < EmailVerification::BaseService
      TOKEN_LENGTH = 6

      def execute
        @token = generate_token

        [token, digest]
      end

      private

      def generate_token
        SecureRandom.random_number(10**TOKEN_LENGTH).to_s.rjust(TOKEN_LENGTH, '0')
      end
    end
  end
end

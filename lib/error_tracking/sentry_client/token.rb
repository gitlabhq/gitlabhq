# frozen_string_literal: true

module ErrorTracking
  class SentryClient
    class Token
      MASKED_TOKEN_REGEX = /\A\*+\z/

      def self.masked_token?(token)
        MASKED_TOKEN_REGEX.match?(token)
      end
    end
  end
end

# frozen_string_literal: true

# rubocop:disable Gitlab/BoundedContexts -- use existing module
module Atlassian
  module JiraConnect
    class JwtValidator
      MAX_JWT_SIZE = 8.kilobytes

      def self.valid_token_size?(token)
        token.present? && token.bytesize <= MAX_JWT_SIZE
      end
    end
  end
end
# rubocop:enable Gitlab/BoundedContexts

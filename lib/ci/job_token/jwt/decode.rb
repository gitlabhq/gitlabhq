# frozen_string_literal: true

module Ci
  module JobToken
    module Jwt
      class Decode < Gitlab::Authz::Token::Decode
        extend ::Ci::JobToken::Jwt::Token

        def initialize(token)
          @token = delete_prefix(token)
        end

        def job
          decode
          subject
        rescue JWT::DecodeError, Gitlab::Graphql::Errors::ArgumentError => error
          Gitlab::ErrorTracking.track_exception(error)
          nil
        end

        private

        def delete_prefix(token)
          token&.delete_prefix(self.class.token_prefix)
        end
      end
    end
  end
end

# frozen_string_literal: true

# Authentication Strategies Builder
#
# AuthBuilder and its child classes, TokenType and SentThrough, support
# declaring allowed authentication strategies with patterns like
# `accept.token_type(:job_token).sent_through(:http_basic)`.
module Gitlab
  module APIAuthentication
    class Builder
      def build
        strategies = Hash.new([])
        yield ::Gitlab::APIAuthentication::TokenTypeBuilder.new(strategies)
        strategies
      end
    end
  end
end

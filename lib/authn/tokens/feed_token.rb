# frozen_string_literal:true

module Authn
  module Tokens
    class FeedToken
      def self.prefix?(plaintext)
        feed_token_prefixes = [::User.prefix_for_feed_token,
          ::User::FEED_TOKEN_PREFIX].uniq

        plaintext.start_with?(*feed_token_prefixes)
      end

      attr_reader :revocable, :source

      def initialize(plaintext, source)
        @revocable = User.find_by_feed_token(plaintext)
        @source = source
      end

      def present_with
        ::API::Entities::User
      end

      def revoke!(current_user)
        raise ::Authn::AgnosticTokenIdentifier::NotFoundError, 'Not Found' if revocable.blank?

        Users::ResetFeedTokenService.new(
          current_user,
          user: revocable,
          source: source
        ).execute
      end
    end
  end
end

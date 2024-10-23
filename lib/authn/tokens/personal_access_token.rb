# frozen_string_literal:true

module Authn
  module Tokens
    class PersonalAccessToken
      def self.prefix?(plaintext)
        plaintext.start_with?(
          ::PersonalAccessToken.token_prefix,
          ApplicationSetting.defaults[:personal_access_token_prefix]
        )
      end

      attr_reader :revocable, :source

      def initialize(plaintext, source)
        @revocable = ::PersonalAccessToken.find_by_token(plaintext)
        @source = source
      end

      def revoke!(current_user)
        raise ::Authn::AgnosticTokenIdentifier::NotFoundError, 'Not Found' if revocable.blank?

        ::PersonalAccessTokens::RevokeService.new(
          current_user,
          token: revocable,
          source: source
        ).execute
      end
    end
  end
end

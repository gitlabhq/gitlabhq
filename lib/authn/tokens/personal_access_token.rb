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

      def present_with
        ::API::Entities::PersonalAccessToken
      end

      def revoke!(current_user)
        raise ::Authn::AgnosticTokenIdentifier::NotFoundError, 'Not Found' if revocable.blank?

        @current_user = current_user
        service = service_by_type

        service.execute
      end

      private

      attr_reader :current_user

      def service_by_type
        user = revocable.user
        if user.project_bot?
          resource_access_token_service
        elsif user.human?
          personal_access_token_service
        else
          raise ::Authn::AgnosticTokenIdentifier::UnsupportedTokenError, 'Unsupported personal access token type'
        end
      end

      def personal_access_token_service
        ::PersonalAccessTokens::RevokeService.new(current_user, token: revocable, source: source)
      end

      def resource_access_token_service
        ::ResourceAccessTokens::RevokeService.new(current_user, resource, revocable)
      end

      def resource
        revocable.user.resource_bot_resource
      end
    end
  end
end

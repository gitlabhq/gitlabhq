# frozen_string_literal:true

module Authn
  module Tokens
    class DeployToken
      def self.prefix?(plaintext)
        plaintext.start_with?(::DeployToken::DEPLOY_TOKEN_PREFIX)
      end

      attr_reader :revocable, :source

      def initialize(plaintext, source)
        @revocable = ::DeployToken.find_by_token(plaintext)
        @source = source
      end

      def present_with
        ::API::Entities::DeployToken
      end

      def revoke!(current_user)
        raise ::Authn::AgnosticTokenIdentifier::NotFoundError, 'Not Found' if revocable.blank?

        @current_user = current_user

        service = service_by_type

        service.source = source
        service.execute
      end

      private

      attr_reader :current_user

      def service_by_type
        if revocable.group
          group_revoke_service
        elsif revocable.project
          project_revoke_service
        else
          raise ::Authn::AgnosticTokenIdentifier::UnsupportedTokenError, 'Unsupported deploy token type'
        end
      end

      def project_revoke_service
        ::Projects::DeployTokens::RevokeService.new(
          project: revocable.project,
          current_user: current_user,
          params: { id: revocable.id }
        )
      end

      def group_revoke_service
        ::Groups::DeployTokens::RevokeService.new(
          revocable.group,
          current_user,
          { id: revocable.id }
        )
      end
    end
  end
end

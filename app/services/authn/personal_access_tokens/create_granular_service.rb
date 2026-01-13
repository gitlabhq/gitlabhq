# frozen_string_literal: true

module Authn
  module PersonalAccessTokens
    class CreateGranularService < BaseService
      def initialize(current_user:, organization:, granular_scopes:, params: {})
        @current_user = current_user
        @organization = organization
        @params = params.dup
        @granular_scopes = granular_scopes
      end

      def execute
        response = nil

        return ServiceResponse.error(message: 'At least one granular scope must be provided') if granular_scopes.empty?

        ::PersonalAccessToken.transaction do
          response = ::PersonalAccessTokens::CreateService.new(
            current_user: current_user, target_user: current_user, params: personal_access_token_params,
            organization_id: organization.id
          ).execute

          raise ActiveRecord::Rollback if response.error?

          token = response.payload[:personal_access_token]

          response = ::Authz::GranularScopeService.new(token).add_granular_scopes(
            granular_scopes
          )

          raise ActiveRecord::Rollback if response.error?

          response = ServiceResponse.success(payload: { personal_access_token: token })
        end

        response
      end

      private

      attr_reader :organization, :granular_scopes

      def personal_access_token_params
        default_params = {
          scopes: [::Gitlab::Auth::GRANULAR_SCOPE],
          granular: true
        }

        default_params.merge(params)
      end
    end
  end
end

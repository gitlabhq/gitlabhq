# frozen_string_literal: true

module Organizations
  class AuthController < ApplicationController
    skip_before_action :verify_authenticity_token, only: [:complete]
    skip_before_action :authenticate_user!, only: [:complete]

    feature_category :system_access

    # Receives JWT-signed payload from IAM Service containing user information
    # after successful OAuth authentication with external provider
    def complete
      return head :forbidden unless Feature.enabled?(:iam_svc_login, :instance)

      return head :unauthorized unless validate_oauth_state

      organization = find_organization
      return head :unauthorized unless organization

      decoded_token = verify_jwt_token
      return head :unauthorized unless decoded_token

      user = find_user_by_identity(decoded_token)
      # rubocop:disable Gitlab/AvoidUserOrganization -- Normally business logic should not rely on user.organization
      # because in the future a user might belong to multiple organizations. Here, we specifically need to check whether
      # the organization_id during OAuth login matches the user's home organization.
      return head :unauthorized unless user && user.organization.id == organization.id

      # rubocop:enable Gitlab/AvoidUserOrganization

      clear_oauth_state_cookie

      sign_in user
      redirect_to root_path
    end

    private

    def find_organization
      Organizations::Organization.find_by_path(payload_params[:organization_organization_path])
    end

    def verify_jwt_token
      Authn::IamService::JwtValidationService.new(
        token: payload_params[:userinfo],
        audience: Authn::IamService::JwtValidationService::IAM_AUTH_CLIENT_HANDLER_AUDIENCE)
        .execute
        .payload[:jwt_payload]
    end

    def find_user_by_identity(user_info_payload)
      provider = user_info_payload['provider']
      extern_uid = user_info_payload['user_info']['id']
      Identity.with_extern_uid(provider, extern_uid).first&.user
    end

    def validate_oauth_state
      stored_state = cookies[iam_auth_cookie_name]
      request_state = payload_params[:state]

      return false if stored_state.blank? || request_state.blank?

      ActiveSupport::SecurityUtils.secure_compare(stored_state, request_state)
    end

    def clear_oauth_state_cookie
      cookies.delete(iam_auth_cookie_name)
    end

    def iam_auth_cookie_name
      'iam_auth_state'
    end

    def payload_params
      params.permit(
        :userinfo,
        :organization_organization_path,
        :state
      )
    end
  end
end

Organizations::AuthController.prepend_mod_with('Organizations::AuthController')

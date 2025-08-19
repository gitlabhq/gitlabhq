# frozen_string_literal: true

module PersonalAccessTokens
  class RotateService
    include Gitlab::InternalEventsTracking

    EXPIRATION_PERIOD = 1.week

    def initialize(current_user, token, resource = nil, params = {})
      @current_user = current_user
      @token = token
      @resource = resource
      @params = params.dup
      @target_user = token.user
    end

    def execute
      return error_response(s_('AccessTokens|Token already revoked')) if token.revoked?

      response = ServiceResponse.success

      PersonalAccessToken.transaction do
        unless token.revoke!
          response = error_response(s_('AccessTokens|Failed to revoke token'))
          raise ActiveRecord::Rollback
        end

        response = create_access_token

        raise ActiveRecord::Rollback unless response.success?

        track_rotation_event
      end

      NotificationService.new.access_token_rotated(token.user, token.name) if response.success?

      response
    end

    private

    attr_reader :current_user, :token, :resource, :params, :target_user

    def create_access_token
      unless valid_access_level?
        return error_response(s_('AccessTokens|Not eligible to rotate token with access level higher than the user'))
      end

      new_token = target_user.personal_access_tokens.create(create_token_params)

      if new_token.persisted?
        update_project_bot_membership(target_user, new_token.expires_at)
        update_project_bot_to_inherit_current_user_external_status

        return success_response(new_token)
      end

      error_response(new_token.errors.full_messages.to_sentence)
    end

    def valid_access_level?
      true
    end

    def update_project_bot_membership(target_user, expires_at)
      return unless target_user.project_bot?

      # Related to https://gitlab.com/gitlab-org/gitlab/-/issues/514328
      # We must retain bot user membership after it became inactive
      # because currently it is the only way to identify to which
      # group/project access token belongs to.
      expires_at = nil # rubocop:disable Lint/ShadowedArgument -- https://gitlab.com/gitlab-org/gitlab/-/issues/514328

      target_user.members.update(expires_at: expires_at)
    end

    # See https://gitlab.com/gitlab-org/gitlab/-/issues/509324
    def update_project_bot_to_inherit_current_user_external_status
      return unless target_user.project_bot?

      target_user.update(external: current_user.external?)
    end

    def expires_at
      if params[:keep_token_lifetime]
        return if token.expires_at.nil?

        token_lifetime = token.expires_at - token.created_at.to_date
        return Time.zone.today + token_lifetime
      end

      return params[:expires_at] if params[:expires_at].present?

      enforced_expiration_date
    end

    def enforced_expiration_date
      return default_expiration_date if Gitlab::CurrentSettings.require_personal_access_token_expiry?

      nil
    end

    def success_response(new_token)
      ServiceResponse.success(payload: { personal_access_token: new_token })
    end

    def error_response(message)
      ServiceResponse.error(message: message)
    end

    def create_token_params
      { name: token.name,
        description: token.description,
        previous_personal_access_token_id: token.id,
        impersonation: token.impersonation,
        scopes: token.scopes,
        expires_at: expires_at,
        organization: token.organization }
    end

    def default_expiration_date
      EXPIRATION_PERIOD.from_now.to_date
    end

    def track_rotation_event
      track_internal_event(
        "rotate_pat",
        user: target_user,
        namespace: target_user.namespace,
        project: nil
      )
    end
  end
end

PersonalAccessTokens::RotateService.prepend_mod

# frozen_string_literal: true

module PersonalAccessTokens
  class RotateService
    EXPIRATION_PERIOD = 1.week

    def initialize(current_user, token)
      @current_user = current_user
      @token = token
    end

    def execute(params = {})
      return error_response(message: _('token already revoked')) if token.revoked?

      response = ServiceResponse.success

      PersonalAccessToken.transaction do
        unless token.revoke!
          response = error_response
          raise ActiveRecord::Rollback
        end

        target_user = token.user
        new_token = target_user.personal_access_tokens.create(create_token_params(token, params))

        if new_token.persisted?
          response = error_response unless update_bot_membership(target_user, new_token.expires_at)
          response = success_response(new_token)
        else
          response = error_response(message: new_token.errors.full_messages.to_sentence)

          raise ActiveRecord::Rollback
        end
      end

      response
    end

    private

    attr_reader :current_user, :token

    def success_response(new_token)
      ServiceResponse.success(payload: { personal_access_token: new_token })
    end

    def error_response(message: _('failed to revoke token'))
      ServiceResponse.error(message: message)
    end

    def create_token_params(token, params)
      expires_at = params[:expires_at] || (Date.today + EXPIRATION_PERIOD)
      {  name: token.name,
         previous_personal_access_token_id: token.id,
         impersonation: token.impersonation,
         scopes: token.scopes,
         expires_at: expires_at }
    end

    def update_bot_membership(target_user, expires_at)
      return unless target_user.project_bot?

      target_user.members.first.update(expires_at: expires_at)
    end
  end
end

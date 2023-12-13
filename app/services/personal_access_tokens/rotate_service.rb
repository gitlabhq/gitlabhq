# frozen_string_literal: true

module PersonalAccessTokens
  class RotateService
    EXPIRATION_PERIOD = 1.week

    def initialize(current_user, token)
      @current_user = current_user
      @token = token
    end

    def execute(params = {})
      return error_response(_('token already revoked')) if token.revoked?

      response = ServiceResponse.success

      PersonalAccessToken.transaction do
        unless token.revoke!
          response = error_response(_('failed to revoke token'))
          raise ActiveRecord::Rollback
        end

        response = create_access_token(params)

        raise ActiveRecord::Rollback unless response.success?
      end

      response
    end

    private

    attr_reader :current_user, :token

    def create_access_token(params)
      target_user = token.user

      new_token = target_user.personal_access_tokens.create(create_token_params(token, params))

      return success_response(new_token) if new_token.persisted?

      error_response(new_token.errors.full_messages.to_sentence)
    end

    def expires_at(params)
      return params[:expires_at] if params[:expires_at]

      params[:expires_at] || EXPIRATION_PERIOD.from_now.to_date
    end

    def success_response(new_token)
      ServiceResponse.success(payload: { personal_access_token: new_token })
    end

    def error_response(message)
      ServiceResponse.error(message: message)
    end

    def create_token_params(token, params)
      { name: token.name,
        previous_personal_access_token_id: token.id,
        impersonation: token.impersonation,
        scopes: token.scopes,
        expires_at: expires_at(params) }
    end
  end
end

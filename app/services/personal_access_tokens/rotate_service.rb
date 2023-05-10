# frozen_string_literal: true

module PersonalAccessTokens
  class RotateService
    EXPIRATION_PERIOD = 1.week

    def initialize(current_user, token)
      @current_user = current_user
      @token = token
    end

    def execute
      return ServiceResponse.error(message: _('token already revoked')) if token.revoked?

      response = ServiceResponse.success

      PersonalAccessToken.transaction do
        unless token.revoke!
          response = ServiceResponse.error(message: _('failed to revoke token'))
          raise ActiveRecord::Rollback
        end

        target_user = token.user
        new_token = target_user.personal_access_tokens.create(create_token_params(token))

        if new_token.persisted?
          response = ServiceResponse.success(payload: { personal_access_token: new_token })
        else
          response = ServiceResponse.error(message: new_token.errors.full_messages.to_sentence)

          raise ActiveRecord::Rollback
        end
      end

      response
    end

    private

    attr_reader :current_user, :token

    def create_token_params(token)
      {  name: token.name,
         impersonation: token.impersonation,
         scopes: token.scopes,
         expires_at: Date.today + EXPIRATION_PERIOD }
    end
  end
end

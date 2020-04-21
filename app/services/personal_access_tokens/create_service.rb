# frozen_string_literal: true

module PersonalAccessTokens
  class CreateService < BaseService
    def initialize(current_user, params = {})
      @current_user = current_user
      @params = params.dup
    end

    def execute
      personal_access_token = current_user.personal_access_tokens.create(params.slice(*allowed_params))

      if personal_access_token.persisted?
        ServiceResponse.success(payload: { personal_access_token: personal_access_token })
      else
        ServiceResponse.error(message: personal_access_token.errors.full_messages.to_sentence)
      end
    end

    private

    def allowed_params
      [
        :name,
        :impersonation,
        :scopes,
        :expires_at
      ]
    end
  end
end

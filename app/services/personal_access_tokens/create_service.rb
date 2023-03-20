# frozen_string_literal: true

module PersonalAccessTokens
  class CreateService < BaseService
    def initialize(current_user:, target_user:, params: {}, concatenate_errors: true)
      @current_user = current_user
      @target_user = target_user
      @params = params.dup
      @ip_address = @params.delete(:ip_address)
      @concatenate_errors = concatenate_errors
    end

    def execute
      return ServiceResponse.error(message: 'Not permitted to create') unless creation_permitted?

      token = target_user.personal_access_tokens.create(params.slice(*allowed_params))

      if token.persisted?
        log_event(token)
        notification_service.access_token_created(target_user, token.name)
        ServiceResponse.success(payload: { personal_access_token: token })
      else
        message = token.errors.full_messages
        message = message.to_sentence if @concatenate_errors

        ServiceResponse.error(message: message, payload: { personal_access_token: token })
      end
    end

    private

    attr_reader :target_user, :ip_address

    def allowed_params
      [
        :name,
        :impersonation,
        :scopes,
        :expires_at
      ]
    end

    def creation_permitted?
      Ability.allowed?(current_user, :create_user_personal_access_token, target_user)
    end

    def log_event(token)
      log_info("PAT CREATION: created_by: '#{current_user.username}', created_for: '#{token.user.username}', token_id: '#{token.id}'")
    end
  end
end

PersonalAccessTokens::CreateService.prepend_mod_with('PersonalAccessTokens::CreateService')

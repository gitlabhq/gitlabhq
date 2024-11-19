# frozen_string_literal: true

module Users
  class ActivateService < BaseService
    def initialize(current_user)
      @current_user = current_user
    end

    def execute(user)
      return error(_('You are not authorized to perform this action'), :forbidden) unless allowed?

      return error(_('Error occurred. A blocked user must be unblocked to be activated'), :forbidden) if user.blocked?

      return success(_('Successfully activated')) if user.active?

      if user.activate
        after_activate_hook(user)
        log_event(user)
        success(_('Successfully activated'))
      else
        error(user.errors.full_messages.to_sentence, :unprocessable_entity)
      end
    end

    private

    attr_reader :current_user

    def allowed?
      can?(current_user, :admin_all_resources)
    end

    def after_activate_hook(user)
      # overridden by EE module
    end

    def log_event(user)
      Gitlab::AppLogger.info(
        message: 'User activated',
        username: user.username.to_s,
        user_id: user.id,
        email: user.email.to_s,
        activated_by: current_user.username.to_s,
        ip_address: current_user.current_sign_in_ip.to_s
      )
    end

    def success(message)
      ::ServiceResponse.success(message: message)
    end

    def error(message, reason)
      ::ServiceResponse.error(message: message, reason: reason)
    end
  end
end

Users::ActivateService.prepend_mod_with('Users::ActivateService')

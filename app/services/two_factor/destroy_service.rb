# frozen_string_literal: true

module TwoFactor
  class DestroyService < ::TwoFactor::BaseService
    def execute
      return error(_('You are not authorized to perform this action')) unless authorized?
      return error(_('Two-factor authentication is not enabled for this user')) unless user.two_factor_enabled?

      result = disable_two_factor

      notify_on_success(user) if result[:status] == :success

      result
    end

    private

    def authorized?
      can?(current_user, :disable_two_factor, user)
    end

    def disable_two_factor
      ::Users::UpdateService.new(current_user, user: user).execute do |user|
        user.disable_two_factor!
      end
    end

    def notify_on_success(user)
      notification_service.disabled_two_factor(user)
    end
  end
end

TwoFactor::DestroyService.prepend_mod_with('TwoFactor::DestroyService')

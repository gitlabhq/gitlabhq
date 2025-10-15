# frozen_string_literal: true

module Webauthn
  class DestroyService < BaseService
    attr_reader :webauthn_registration, :user, :current_user

    def initialize(current_user, user, second_factor_webauthn_registrations_id)
      @current_user = current_user
      @user = user
      @webauthn_registration = user.second_factor_webauthn_registrations.find(second_factor_webauthn_registrations_id)
    end

    def execute
      return error(_('You are not authorized to perform this action')) unless authorized?

      result = destroy_webauthn_device

      if result[:status] == :success
        notify_on_success(user, webauthn_registration.name)

        unless user.two_factor_enabled?
          user.reset_backup_codes!
          notification_service.disabled_two_factor(user)
        end
      end

      result
    end

    private

    def authorized?
      current_user.can?(:disable_two_factor, user)
    end

    def destroy_webauthn_device
      ::Users::UpdateService.new(current_user, user: user).execute do |user|
        user.destroy_webauthn_device(webauthn_registration.id)
      end
    end

    def notify_on_success(user, device_name)
      notification_service.disabled_two_factor(user, :webauthn, { device_name: device_name })
    end
  end
end

Webauthn::DestroyService.prepend_mod

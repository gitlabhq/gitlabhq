# frozen_string_literal: true

module Authn
  module Passkey
    class DestroyService < BaseService
      attr_reader :passkey, :user, :current_user

      def initialize(current_user, user, passkey_id)
        @current_user = current_user
        @user = user
        @passkey = user.passkeys.find(passkey_id)
      end

      def execute
        return ServiceResponse.error(message: _("You are not authorized to perform this action")) unless authorized?

        passkey.destroy!

        notify_on_success(user, passkey.name)

        ServiceResponse.success(
          message: _("Passkey has been deleted!")
        )
      end

      private

      def authorized?
        current_user.can?(:disable_passkey, user)
      end

      def notify_on_success(user, device_name)
        notification_service.disabled_two_factor(user, :passkey, { device_name: device_name })
      end
    end
  end
end

Authn::Passkey::DestroyService.prepend_mod

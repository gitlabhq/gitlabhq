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

        ServiceResponse.success(
          message: _("Passkey has been deleted!")
        )
      end

      private

      def authorized?
        current_user.can?(:disable_passkey, user)
      end
    end
  end
end

# frozen_string_literal: true

module Webauthn
  class DestroyService < BaseService
    attr_reader :webauthn_registration, :user, :current_user

    def initialize(current_user, user, webauthn_registrations_id)
      @current_user = current_user
      @user = user
      @webauthn_registration = user.webauthn_registrations.find(webauthn_registrations_id)
    end

    def execute
      return error(_('You are not authorized to perform this action')) unless authorized?

      webauthn_registration.destroy
      user.reset_backup_codes! if last_two_factor_registration?
    end

    private

    def last_two_factor_registration?
      user.webauthn_registrations.empty? && !user.otp_required_for_login?
    end

    def authorized?
      current_user.can?(:disable_two_factor, user)
    end
  end
end

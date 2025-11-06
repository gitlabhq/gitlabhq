# frozen_string_literal: true

module Gitlab
  module Auth
    class TwoFactorAuthVerifier
      attr_reader :current_user, :request, :treat_email_otp_as_2fa

      # ==== Parameters
      # +current_user+: User
      #   The current user
      # +request+: Default: nil
      # +treat_email_otp_as_2fa+: Boolean. Default: false
      #   If a user is enrolled in email-based OTP and this attribute is true, we
      #   treat Email-based OTP like 2FA. This is useful when we want to block
      #   things like password-authenticatable endpoints. Fails secure.
      #   Conversely when the attribute is false, Email-OTP does not  count.
      #   This is useful when we want high assurance, like  Instance / Group 2FA
      #   enforcement settings.
      def initialize(current_user, request = nil, treat_email_otp_as_2fa: false)
        @current_user = current_user
        @request = request
        @treat_email_otp_as_2fa = treat_email_otp_as_2fa
      end

      def two_factor_authentication_enforced?
        (two_factor_authentication_required? && two_factor_grace_period_expired?) ||
          (treat_email_otp_as_2fa && current_user&.email_based_otp_required?)
      end

      # -- Admin mode does not matter in the context of verifying for two factor statuses
      def two_factor_authentication_required?
        return false if allow_2fa_bypass_for_provider

        Gitlab::CurrentSettings.require_two_factor_authentication? ||
          current_user&.require_two_factor_authentication_from_group? ||
          (Gitlab::CurrentSettings.require_admin_two_factor_authentication && current_user&.can_access_admin_area?)
      end

      def two_factor_authentication_reason
        if Gitlab::CurrentSettings.require_two_factor_authentication?
          :global
        elsif Gitlab::CurrentSettings.require_admin_two_factor_authentication && current_user&.can_access_admin_area?
          :admin_2fa
        elsif current_user&.require_two_factor_authentication_from_group?
          :group
        else
          false
        end
      end

      def current_user_needs_to_setup_two_factor?
        current_user && !current_user.temp_oauth_email? && !current_user.two_factor_enabled?
      end

      def two_factor_grace_period
        periods = [Gitlab::CurrentSettings.two_factor_grace_period]
        periods << current_user.two_factor_grace_period if current_user&.require_two_factor_authentication_from_group?
        periods.min
      end

      def two_factor_grace_period_expired?
        time = current_user&.otp_grace_period_started_at

        return false unless time

        two_factor_grace_period.hours.since(time).past?
      end

      def allow_2fa_bypass_for_provider
        request.session[:provider_2FA].present? if request
      end
    end
  end
end

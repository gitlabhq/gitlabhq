# frozen_string_literal: true

module Gitlab
  module Auth
    class TwoFactorAuthVerifier
      attr_reader :current_user, :request

      def initialize(current_user, request = nil)
        @current_user = current_user
        @request = request
      end

      def two_factor_authentication_enforced?
        two_factor_authentication_required? && two_factor_grace_period_expired?
      end

      # rubocop:disable Cop/UserAdmin -- Admin mode does not matter in the context of verifying for two factor statuses
      def two_factor_authentication_required?
        return false if allow_2fa_bypass_for_provider

        Gitlab::CurrentSettings.require_two_factor_authentication? ||
          current_user&.require_two_factor_authentication_from_group? ||
          (Gitlab::CurrentSettings.require_admin_two_factor_authentication && current_user&.admin?) # rubocop:disable Cop/UserAdmin -- It should be applied to any administrator user regardless of admin mode
      end

      def two_factor_authentication_reason
        if Gitlab::CurrentSettings.require_two_factor_authentication?
          :global
        elsif Gitlab::CurrentSettings.require_admin_two_factor_authentication && current_user&.admin?
          :admin_2fa
        elsif current_user&.require_two_factor_authentication_from_group?
          :group
        else
          false
        end
      end
      # rubocop:enable Cop/UserAdmin

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

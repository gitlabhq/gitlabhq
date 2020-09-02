# frozen_string_literal: true

module Gitlab
  module Auth
    class TwoFactorAuthVerifier
      attr_reader :current_user

      def initialize(current_user)
        @current_user = current_user
      end

      def two_factor_authentication_required?
        Gitlab::CurrentSettings.require_two_factor_authentication? ||
          current_user&.require_two_factor_authentication_from_group?
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

        two_factor_grace_period.hours.since(time) < Time.current
      end
    end
  end
end

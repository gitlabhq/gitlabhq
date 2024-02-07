# frozen_string_literal: true

module Users
  module EmailVerification
    class ValidateTokenService < EmailVerification::BaseService
      include ActionView::Helpers::DateHelper

      TOKEN_VALID_FOR_MINUTES = 60

      def initialize(attr:, user:, token:)
        super(attr: attr, user: user)

        @token = token
      end

      def execute
        return failure(:rate_limited) if verification_rate_limited?
        return failure(:invalid) unless valid?
        return failure(:expired) if expired_token?

        success
      end

      private

      attr_reader :user

      def verification_rate_limited?
        Gitlab::ApplicationRateLimiter.throttled?(:email_verification, scope: user[attr])
      end

      def valid?
        return false unless token.present?

        Devise.secure_compare(user[attr], digest)
      end

      def expired_token?
        generated_at = case attr
                       when :unlock_token then user.locked_at
                       when :confirmation_token then user.confirmation_sent_at
                       end

        generated_at < TOKEN_VALID_FOR_MINUTES.minutes.ago
      end

      def success
        { status: :success }
      end

      def failure(reason)
        {
          status: :failure,
          reason: reason,
          message: failure_message(reason)
        }
      end

      def failure_message(reason)
        case reason
        when :rate_limited
          format(s_("IdentityVerification|You've reached the maximum amount of tries. "\
             'Wait %{interval} or send a new code and try again.'), interval: email_verification_interval)
        when :expired
          s_('IdentityVerification|The code has expired. Send a new code and try again.')
        when :invalid
          s_('IdentityVerification|The code is incorrect. Enter it again, or send a new code.')
        end
      end

      def email_verification_interval
        interval_in_seconds = Gitlab::ApplicationRateLimiter.rate_limits[:email_verification][:interval]
        distance_of_time_in_words(interval_in_seconds)
      end
    end
  end
end

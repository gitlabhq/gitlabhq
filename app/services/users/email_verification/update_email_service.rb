# frozen_string_literal: true

module Users
  module EmailVerification
    class UpdateEmailService
      include ActionView::Helpers::DateHelper

      RATE_LIMIT = :email_verification_code_send

      def initialize(user:)
        @user = user
      end

      def execute(email:)
        return failure(:rate_limited) if rate_limited?
        return failure(:already_offered) if already_offered?
        return failure(:no_change) if no_change?(email)
        return failure(:validation_error) unless update_email

        success
      end

      private

      attr_reader :user

      def rate_limited?
        Gitlab::ApplicationRateLimiter.throttled?(RATE_LIMIT, scope: user)
      end

      def already_offered?
        user.email_reset_offered_at.present?
      end

      def no_change?(email)
        user.email = email
        !user.will_save_change_to_email?
      end

      def update_email
        user.skip_confirmation_notification!
        user.save
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
          interval = distance_of_time_in_words(Gitlab::ApplicationRateLimiter.rate_limits[RATE_LIMIT][:interval])
          format(
            s_("IdentityVerification|You've reached the maximum amount of tries. Wait %{interval} and try again."),
            interval: interval
          )
        when :already_offered
          s_('IdentityVerification|Email update is only offered once.')
        when :no_change
          s_('IdentityVerification|A code has already been sent to this email address. ' \
             'Check your spam folder or enter another email address.')
        when :validation_error
          user.errors.full_messages.join(' ')
        end
      end
    end
  end
end

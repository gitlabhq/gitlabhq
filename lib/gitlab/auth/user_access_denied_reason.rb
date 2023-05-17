# frozen_string_literal: true

module Gitlab
  module Auth
    class UserAccessDeniedReason
      def initialize(user)
        @user = user
      end

      def rejection_message
        case rejection_type
        when :internal
          "This action cannot be performed by internal users"
        when :blocked_pending_approval
          "Your account is pending approval from your administrator and hence blocked."
        when :terms_not_accepted
          "You (#{@user.to_reference}) must accept the Terms of Service in order to perform this action. "\
          "To accept these terms, please access GitLab from a web browser at #{Gitlab.config.gitlab.url}."
        when :deactivated
          "Your account has been deactivated by your administrator. "\
          "Please log back in from a web browser to reactivate your account at #{Gitlab.config.gitlab.url}"
        when :unconfirmed
          "Your primary email address is not confirmed. "\
          "Please check your inbox for the confirmation instructions. "\
          "In case the link is expired, you can request a new confirmation email at #{Rails.application.routes.url_helpers.new_user_confirmation_url}"
        when :blocked
          "Your account has been blocked."
        when :password_expired
          "Your password expired. "\
          "Please access GitLab from a web browser to update your password."
        else
          "Your request has been rejected for an unknown reason."\
          "Please contact your GitLab administrator and/or GitLab Support."
        end
      end

      private

      def rejection_type
        if @user.internal?
          :internal
        elsif @user.blocked_pending_approval?
          :blocked_pending_approval
        elsif @user.required_terms_not_accepted?
          :terms_not_accepted
        elsif @user.deactivated?
          :deactivated
        elsif !@user.confirmed?
          :unconfirmed
        elsif @user.blocked?
          :blocked
        elsif @user.password_expired?
          :password_expired
        else
          :blocked
        end
      end
    end
  end
end

Gitlab::Auth::UserAccessDeniedReason.prepend_mod

# frozen_string_literal: true

module Emails
  class DestroyService < ::Emails::BaseService
    def execute(email)
      raise StandardError, 'Cannot delete primary email' if email.user_primary_email?

      return unless email.destroy

      reset_email_in_notification_settings!(email)
      update_secondary_emails!(email.email)
    end

    private

    def reset_email_in_notification_settings!(deleted_email)
      NotificationSetting.reset_email_for_user!(deleted_email)
    end

    def update_secondary_emails!(deleted_email)
      result = ::Users::UpdateService.new(@current_user, user: @user).execute do |user|
        user.unset_secondary_emails_matching_deleted_email!(deleted_email)
      end

      result[:status] == :success
    end
  end
end

Emails::DestroyService.prepend_mod_with('Emails::DestroyService')

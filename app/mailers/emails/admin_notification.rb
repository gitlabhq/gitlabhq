# frozen_string_literal: true

module Emails
  module AdminNotification
    def send_admin_notification(user_id, subject, body)
      user = User.find(user_id)
      email = user.notification_email_or_default
      @unsubscribe_url = unsubscribe_url(email: Base64.urlsafe_encode64(email))
      @body = body
      mail to: email, subject: subject
    end

    def send_unsubscribed_notification(user_id)
      user = User.find(user_id)
      email = user.notification_email_or_default
      mail to: email, subject: "Unsubscribed from GitLab administrator notifications"
    end

    def user_auto_banned_email(admin_id, user_id, max_project_downloads:, within_seconds:, group: nil)
      admin = User.find(admin_id)
      @user = User.find(user_id)
      @max_project_downloads = max_project_downloads
      @within_minutes = within_seconds / 60
      @ban_scope = if group.present?
                     _('your group (%{group_name})' % { group_name: group.name })
                   else
                     _('your GitLab instance')
                   end

      Gitlab::I18n.with_locale(admin.preferred_language) do
        email_with_layout(
          to: admin.notification_email_or_default,
          subject: subject(_("We've detected unusual activity")))
      end
    end
  end
end

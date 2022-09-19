# frozen_string_literal: true

module Emails
  module AdminNotification
    def send_admin_notification(user_id, subject, body)
      user = User.find(user_id)
      email = user.notification_email_or_default
      @unsubscribe_url = unsubscribe_url(email: Base64.urlsafe_encode64(email))
      @body = body
      mail_with_locale to: email, subject: subject
    end

    def send_unsubscribed_notification(user_id)
      user = User.find(user_id)
      email = user.notification_email_or_default
      mail_with_locale to: email, subject: "Unsubscribed from GitLab administrator notifications"
    end
  end
end

Emails::AdminNotification.prepend_mod

module Emails
  module AdminNotification
    def send_admin_notification(user_id, subject, body)
      email = recipient(user_id)
      @unsubscribe_url = unsubscribe_url(email: Base64.urlsafe_encode64(email))
      @body = body
      mail to: email, subject: subject
    end
  end
end

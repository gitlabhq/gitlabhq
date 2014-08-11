module Emails
  module AdminNotification
    def send_admin_notification(user_id, subject, body)
      email = recipient(user_id)
      @unsubscribe_url = public_unsubscribe_url(email: email)
      @body = body
      mail to: email, subject: subject
    end
  end
end
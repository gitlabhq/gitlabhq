module Emails
  module AdminNotification
    def send_admin_notification(user_id, subject, body)
      email = recipient(user_id)
      @unsubscribe_url = unsubscribe_url(email: CGI.escape(email))
      @body = body
      mail to: email, subject: subject
    end
  end
end
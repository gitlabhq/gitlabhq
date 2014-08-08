module Emails
  module AdminNotification
    def send_admin_notification(user_id, subject, body)
      @body = body
      mail to: recipient(user_id), subject: subject
    end
  end
end
# Read about interceptors in http://guides.rubyonrails.org/action_mailer_basics.html#intercepting-emails
class DisableEmailInterceptor

  def self.delivering_email(message)
    message.perform_deliveries = false
    Rails.logger.info "Emails disabled! Interceptor prevented sending mail #{message.subject}"
  end
end

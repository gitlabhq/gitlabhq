# Read about interceptors in http://guides.rubyonrails.org/action_mailer_basics.html#intercepting-emails
class EmailTemplateInterceptor
  include Gitlab::CurrentSettings

  def self.delivering_email(message)
    # Remove HTML part if HTML emails are disabled.
    unless current_application_settings.html_emails_enabled
      message.parts.delete_if do |part|
        part.content_type.start_with?('text/html')
      end
    end
  end
end

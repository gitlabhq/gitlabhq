# To enable smtp email delivery for your GitLab instance do next: 
# 1. Change config/environments/production.rb to use smtp
#    config.action_mailer.delivery_method = :smtp
# 2. Rename this file to smtp_settings.rb
# 3. Edit settings inside this file
# 4. Restart GitLab instance
#
if Gitlab::Application.config.action_mailer.delivery_method == :smtp
  ActionMailer::Base.smtp_settings = {
    address: ENV['SMTP_HOST'],
    port: ENV['SMTP_PORT'],
    user_name: ENV['SMTP_USERNAME'],
    password: ENV['SMTP_PASSWORD'],
    domain: ENV['SMTP_DOMAIN'],
    authentication: :login,
    enable_starttls_auto: true
  }
end
# Be sure to restart your server when you modify this file.

require 'gitlab/current_settings'

def configure_sentry
  # allow it to fail: it may do so when create_from_defaults is executed before migrations are actually done
  begin
    sentry_enabled = Gitlab::CurrentSettings.current_application_settings.sentry_enabled
  rescue
    sentry_enabled = false
  end

  if sentry_enabled
    Raven.configure do |config|
      config.dsn = Gitlab::CurrentSettings.current_application_settings.sentry_dsn
      config.release = Gitlab::REVISION

      # Sanitize fields based on those sanitized from Rails.
      config.sanitize_fields = Rails.application.config.filter_parameters.map(&:to_s)
      # Sanitize authentication headers
      config.sanitize_http_headers = %w[Authorization Private-Token]
      config.tags = { program: Gitlab::Sentry.program_context }
    end
  end
end

configure_sentry if Rails.env.production?

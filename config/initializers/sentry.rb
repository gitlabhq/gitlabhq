# Be sure to restart your server when you modify this file.

require 'gitlab/current_settings'

def configure_sentry
  if Gitlab::Sentry.enabled?
    Raven.configure do |config|
      config.dsn = Gitlab.config.sentry.dsn
      config.release = Gitlab.revision
      config.current_environment = Gitlab.config.sentry.environment

      # Sanitize fields based on those sanitized from Rails.
      config.sanitize_fields = Rails.application.config.filter_parameters.map(&:to_s)
      # Sanitize authentication headers
      config.sanitize_http_headers = %w[Authorization Private-Token]
      config.tags = { program: Gitlab.process_name }
      # Debugging for https://gitlab.com/gitlab-org/gitlab-ce/issues/57727
      config.before_send = lambda do |event, hint|
        if ActiveModel::MissingAttributeError === hint[:exception]
          columns_hash = ActiveRecord::Base
                           .connection
                           .schema_cache
                           .instance_variable_get(:@columns_hash)
                           .map { |k, v| [k, v.map(&:first)] }
                           .to_h

          event.extra.merge!(columns_hash)
        end

        event
      end
    end
  end
end

configure_sentry if Rails.env.production? || Rails.env.development?

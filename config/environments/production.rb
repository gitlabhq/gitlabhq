# frozen_string_literal: true

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Disable Rails's static asset server (Apache or nginx will already do this)
  config.public_file_server.enabled = false

  # Compress JavaScripts and CSS.
  config.assets.js_compressor = :terser
  # config.assets.css_compressor = :sass

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = false

  # Generate digests for assets URLs
  config.assets.digest = true

  # Enable compression of compiled assets using gzip.
  config.assets.compress = true

  # Defaults to nil and saved in location specified by config.assets.prefix
  # config.assets.manifest = YOUR_PATH

  # Specifies the header that your server uses for sending files
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # Include generic and useful information about system operation, but avoid logging too much
  # information to avoid inadvertent exposure of personally identifiable information (PII).
  # Note: This configuration does not affect the log level of `Gitlab::Logger` and its subclasses.
  config.log_level = Gitlab::Utils.to_rails_log_level(ENV["GITLAB_LOG_LEVEL"], :info)

  # Suppress 'Rendered template ...' messages in the log
  # source: http://stackoverflow.com/a/16369363
  %w[render_template render_partial render_collection].each do |event|
    ActiveSupport::Notifications.unsubscribe "#{event}.action_view"
  end

  # Prepend all log lines with the following tags
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Do not dump schema after migrations.
  config.active_record.dump_schema_after_migration = false

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  # config.assets.precompile += %w( search.js )

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe! unless $rails_rake_task

  config.action_mailer.delivery_method = :sendmail
  # Defaults to:
  # # config.action_mailer.sendmail_settings = {
  # #   location: '/usr/sbin/sendmail',
  # #   arguments: '-i -t'
  # # }
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true

  config.eager_load = true
end

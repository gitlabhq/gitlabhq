Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Show full error reports and disable caching
  config.active_record.verbose_query_logs  = true
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations
  config.active_record.migration_error = :page_load

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  # config.assets.debug = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # For having correct urls in mails
  config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }
  # Open sent mails in browser
  config.action_mailer.delivery_method = :letter_opener_web
  # Log mail delivery errors
  config.action_mailer.raise_delivery_errors = true
  # Don't make a mess when bootstrapping a development environment
  config.action_mailer.perform_deliveries = (ENV['BOOTSTRAP'] != '1')
  config.action_mailer.preview_path = 'app/mailers/previews'

  config.eager_load = false

  # Do not log asset requests
  config.assets.quiet = true

  config.allow_concurrency = defined?(::Puma)

  # BetterErrors live shell (REPL) on every stack frame
  BetterErrors::Middleware.allow_ip!("127.0.0.1/0")
end

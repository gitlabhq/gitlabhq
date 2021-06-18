# frozen_string_literal: true

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = Gitlab::Utils.to_boolean(ENV['CACHE_CLASSES'], default: false)

  # Show full error reports and disable caching
  config.active_record.verbose_query_logs  = true
  config.consider_all_requests_local       = true

  if Rails.root.join('tmp', 'caching-dev.txt').exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true
  else
    config.action_controller.perform_caching = false
  end

  # Show a warning when a large data set is loaded into memory
  config.active_record.warn_on_records_fetched_greater_than = 1000

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
  config.action_mailer.preview_path = "#{Rails.root}{/ee,}/app/mailers/previews"

  config.eager_load = false

  # Do not log asset requests
  config.assets.quiet = true

  # BetterErrors live shell (REPL) on every stack frame
  BetterErrors::Middleware.allow_ip!("127.0.0.1/0")

  # Reassign some performance related settings when we profile the app
  if Gitlab::Utils.to_boolean(ENV['RAILS_PROFILE'].to_s)
    warn "Hot-reloading is disabled as you are running with RAILS_PROFILE enabled"
    config.cache_classes = true
    config.eager_load = true
    config.active_record.migration_error = false
    config.active_record.verbose_query_logs = false
    config.action_view.cache_template_loading = true

    config.middleware.delete BetterErrors::Middleware
  end
end

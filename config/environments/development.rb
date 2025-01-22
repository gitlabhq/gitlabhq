# frozen_string_literal: true

require 'gitlab/middleware/strip_cookies'

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

  # Raise an error on page load if there are pending migrations
  config.active_record.migration_error = :page_load

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Configure static asset server for e2e:test-on-gdk
  config.assets.compile = !Gitlab::Utils.to_boolean(ENV['GITLAB_DEVELOPMENT_USE_PRECOMPILED_ASSETS'], default: false)
  # There is no need to check if assets are precompiled locally
  # To debug AssetNotPrecompiled errors locally, set CHECK_PRECOMPILED_ASSETS to true
  config.assets.check_precompiled_asset = Gitlab::Utils.to_boolean(ENV['CHECK_PRECOMPILED_ASSETS'], default: false)

  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  # config.assets.debug = true

  # Annotate rendered view with template file names as HTML comments
  config.action_view.annotate_rendered_view_with_filenames = true

  # ViewComponent & Lookbook previews
  config.view_component.default_preview_layout = "component_preview"
  config.view_component.preview_route = "/-/view_component/previews"
  config.lookbook.preview_paths = ["#{config.root}/spec/components/previews"]
  # Push preview path now to prevent FrozenError during initialzer
  config.autoload_paths.push("#{config.root}/spec/components/previews")

  config.lookbook.page_paths = ["#{config.root}/spec/components/docs"]
  config.lookbook.preview_params_options_eval = true
  config.lookbook.preview_display_options = {
    layout: %w[fixed fluid],
    theme: ["light", "dark (alpha)"]
  }

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Open sent mails in browser
  config.action_mailer.delivery_method = :letter_opener_web
  # Log mail delivery errors
  config.action_mailer.raise_delivery_errors = true
  # Don't make a mess when bootstrapping a development environment
  config.action_mailer.perform_deliveries = (ENV['BOOTSTRAP'] != '1')

  if ::Gitlab.next_rails?
    config.action_mailer.preview_paths = [GitlabEdition.path_glob('app/mailers/previews')]
  else
    config.action_mailer.preview_path = GitlabEdition.path_glob('app/mailers/previews')
  end

  config.eager_load = false

  # Do not log asset requests
  config.assets.quiet = true

  # Disable inotify watchers in cases when we don't need them
  if config.cache_classes || ::Gitlab::Runtime.console? || ::Gitlab::Runtime.rake?
    # Rails ignores reload_classes_only_on_change if cache_classes is enabled, but
    # the lookbook gem appears to use this variable to watch files. Disabling
    # this variable ensures that a file watcher isn't loaded, which appears to save
    # 8 threads (2 workers * 4 threads/worker):
    # https://github.com/ViewComponent/lookbook/blob/v2.0.5/lib/lookbook/engine.rb#L65
    # https://github.com/ViewComponent/lookbook/blob/v2.0.5/lib/lookbook/reloaders.rb#L15-L18
    config.reload_classes_only_on_change = false
    # Use the simple file watcher to prevent factory_bot_rails from launching 4 file watcher threads:
    # https://github.com/thoughtbot/factory_bot_rails/blob/v6.2.0/lib/factory_bot_rails/reloader.rb#L29
    config.file_watcher = ActiveSupport::FileUpdateChecker
  else
    # Use 'listen' gem to watch for file changes and improve performance
    # See: https://guides.rubyonrails.org/configuring.html#config-file-watcher
    config.file_watcher = ActiveSupport::EventedFileUpdateChecker
  end

  # BetterErrors live shell (REPL) on every stack frame
  BetterErrors::Middleware.allow_ip!("127.0.0.1/0")
  # Disable REPL due to security concerns.
  BetterErrors.binding_of_caller_available = false

  # Reassign some performance related settings when we profile the app
  if Gitlab::Utils.to_boolean(ENV['RAILS_PROFILE'].to_s)
    warn "Hot-reloading is disabled as you are running with RAILS_PROFILE enabled"
    config.cache_classes = true
    config.eager_load = true
    config.active_record.migration_error = false
    config.active_record.verbose_query_logs = false
    config.action_view.cache_template_loading = true
    config.action_view.annotate_rendered_view_with_filenames = false

    config.middleware.delete BetterErrors::Middleware
  end

  config.middleware.insert_before(
    ActionDispatch::Cookies, Gitlab::Middleware::StripCookies, paths: [%r{^/assets/}]
  )

  config.log_level = Gitlab::Utils.to_rails_log_level(ENV["GITLAB_LOG_LEVEL"], :debug)
end

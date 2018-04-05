require File.expand_path('../boot', __FILE__)

require 'rails/all'

Bundler.require(:default, Rails.env)

module Gitlab
  class Application < Rails::Application
    require_dependency Rails.root.join('lib/gitlab/redis/wrapper')
    require_dependency Rails.root.join('lib/gitlab/redis/cache')
    require_dependency Rails.root.join('lib/gitlab/redis/queues')
    require_dependency Rails.root.join('lib/gitlab/redis/shared_state')
    require_dependency Rails.root.join('lib/gitlab/request_context')
    require_dependency Rails.root.join('lib/gitlab/current_settings')

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Sidekiq uses eager loading, but directories not in the standard Rails
    # directories must be added to the eager load paths:
    # https://github.com/mperham/sidekiq/wiki/FAQ#why-doesnt-sidekiq-autoload-my-rails-application-code
    # Also, there is no need to add `lib` to autoload_paths since autoloading is
    # configured to check for eager loaded paths:
    # https://github.com/rails/rails/blob/v4.2.6/railties/lib/rails/engine.rb#L687
    # This is a nice reference article on autoloading/eager loading:
    # http://blog.arkency.com/2014/11/dont-forget-about-eager-load-when-extending-autoload
    config.eager_load_paths.push(*%W[#{config.root}/lib
                                     #{config.root}/app/models/badges
                                     #{config.root}/app/models/hooks
                                     #{config.root}/app/models/members
                                     #{config.root}/app/models/project_services
                                     #{config.root}/app/workers/concerns
                                     #{config.root}/app/services/concerns
                                     #{config.root}/app/serializers/concerns
                                     #{config.root}/app/finders/concerns])

    config.generators.templates.push("#{config.root}/generator_templates")

    # Rake tasks ignore the eager loading settings, so we need to set the
    # autoload paths explicitly
    config.autoload_paths = config.eager_load_paths.dup

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    config.i18n.enforce_available_locales = false

    # Translation for AR attrs is not working well for POROs like WikiPage
    config.gettext_i18n_rails.use_for_active_record_attributes = false

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    #
    # Parameters filtered:
    # - Any parameter ending with `token`
    # - Any parameter containing `password`
    # - Any parameter containing `secret`
    # - Two-factor tokens (:otp_attempt)
    # - Repo/Project Import URLs (:import_url)
    # - Build traces (:trace)
    # - Build variables (:variables)
    # - GitLab Pages SSL cert/key info (:certificate, :encrypted_key)
    # - Webhook URLs (:hook)
    # - Sentry DSN (:sentry_dsn)
    # - Deploy keys (:key)
    config.filter_parameters += [/token$/, /password/, /secret/]
    config.filter_parameters += %i(
      certificate
      encrypted_key
      hook
      import_url
      key
      otp_attempt
      sentry_dsn
      trace
      variables
    )

    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    # config.active_record.schema_format = :sql

    # Configure webpack
    config.webpack.config_file = "config/webpack.config.js"
    config.webpack.output_dir  = "public/assets/webpack"
    config.webpack.public_path = "assets/webpack"

    # Webpack dev server configuration is handled in initializers/static_files.rb
    config.webpack.dev_server.enabled = false

    # Enable the asset pipeline
    config.assets.enabled = true

    # Support legacy unicode file named img emojis, `1F939.png`
    config.assets.paths << Gemojione.images_path
    config.assets.paths << "#{config.root}/vendor/assets/fonts"

    config.assets.precompile << "print.css"
    config.assets.precompile << "notify.css"
    config.assets.precompile << "mailers/*.css"
    config.assets.precompile << "xterm/xterm.css"
    config.assets.precompile << "performance_bar.css"
    config.assets.precompile << "lib/ace.js"
    config.assets.precompile << "test.css"
    config.assets.precompile << "locale/**/app.js"

    # Import gitlab-svgs directly from vendored directory
    config.assets.paths << "#{config.root}/node_modules/@gitlab-org/gitlab-svgs/dist"
    config.assets.precompile << "icons.svg"
    config.assets.precompile << "icons.json"
    config.assets.precompile << "illustrations/*.svg"

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    config.action_view.sanitized_allowed_protocols = %w(smb)

    config.middleware.insert_after Warden::Manager, Rack::Attack

    # Allow access to GitLab API from other domains
    config.middleware.insert_before Warden::Manager, Rack::Cors do
      allow do
        origins Gitlab.config.gitlab.url
        resource '/api/*',
          credentials: true,
          headers: :any,
          methods: :any,
          expose: ['Link', 'X-Total', 'X-Total-Pages', 'X-Per-Page', 'X-Page', 'X-Next-Page', 'X-Prev-Page']
      end

      # Cross-origin requests must not have the session cookie available
      allow do
        origins '*'
        resource '/api/*',
          credentials: false,
          headers: :any,
          methods: :any,
          expose: ['Link', 'X-Total', 'X-Total-Pages', 'X-Per-Page', 'X-Page', 'X-Next-Page', 'X-Prev-Page']
      end
    end

    # Use caching across all environments
    caching_config_hash = Gitlab::Redis::Cache.params
    caching_config_hash[:namespace] = Gitlab::Redis::Cache::CACHE_NAMESPACE
    caching_config_hash[:expires_in] = 2.weeks # Cache should not grow forever
    if Sidekiq.server? # threaded context
      caching_config_hash[:pool_size] = Sidekiq.options[:concurrency] + 5
      caching_config_hash[:pool_timeout] = 1
    end

    config.cache_store = :redis_store, caching_config_hash

    config.active_record.raise_in_transactional_callbacks = true

    config.active_job.queue_adapter = :sidekiq

    # This is needed for gitlab-shell
    ENV['GITLAB_PATH_OUTSIDE_HOOK'] = ENV['PATH']
    ENV['GIT_TERMINAL_PROMPT'] = '0'

    # Gitlab Read-only middleware support
    config.middleware.insert_after ActionDispatch::Flash, '::Gitlab::Middleware::ReadOnly'

    config.generators do |g|
      g.factory_bot false
    end

    config.after_initialize do
      Rails.application.reload_routes!

      project_url_helpers = Module.new do
        extend ActiveSupport::Concern

        Gitlab::Application.routes.named_routes.helper_names.each do |name|
          next unless name.include?('namespace_project')

          define_method(name.sub('namespace_project', 'project')) do |project, *args|
            send(name, project&.namespace, project, *args) # rubocop:disable GitlabSecurity/PublicSend
          end
        end
      end

      # We add the MilestonesRoutingHelper because we know that this does not
      # conflict with the methods defined in `project_url_helpers`, and we want
      # these methods available in the same places.
      Gitlab::Routing.add_helpers(project_url_helpers)
      Gitlab::Routing.add_helpers(MilestonesRoutingHelper)
    end
  end

  # This method is used for smooth upgrading from the current Rails 4.x to Rails 5.0.
  # https://gitlab.com/gitlab-org/gitlab-ce/issues/14286
  def self.rails5?
    ENV["RAILS5"].in?(%w[1 true])
  end
end

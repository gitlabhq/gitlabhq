require File.expand_path('../boot', __FILE__)

require 'rails/all'

Bundler.require(:default, Rails.env)

module Gitlab
  class Application < Rails::Application
    require_dependency Rails.root.join('lib/gitlab/redis')

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
    config.eager_load_paths.push(*%W(#{config.root}/lib
                                     #{config.root}/app/models/ci
                                     #{config.root}/app/models/hooks
                                     #{config.root}/app/models/members
                                     #{config.root}/app/models/project_services))

    config.generators.templates.push("#{config.root}/generator_templates")

    # EE specific paths.
    config.eager_load_paths.push("#{config.root}/app/workers/concerns")

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    config.i18n.enforce_available_locales = false

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    #
    # Parameters filtered:
    # - Password (:password, :password_confirmation)
    # - Private tokens (:private_token)
    # - Two-factor tokens (:otp_attempt)
    # - Repo/Project Import URLs (:import_url)
    # - Build variables (:variables)
    # - GitLab Pages SSL cert/key info (:certificate, :encrypted_key)
    # - Webhook URLs (:hook)
    # - Sentry DSN (:sentry_dsn)
    # - Deploy keys (:key)
    config.filter_parameters += %i(
      certificate
      encrypted_key
      hook
      import_url
      key
      otp_attempt
      password
      password_confirmation
      private_token
      sentry_dsn
      variables
    )

    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    # config.active_record.schema_format = :sql

    # Enable the asset pipeline
    config.assets.enabled = true
    config.assets.paths << Gemojione.images_path
    config.assets.precompile << "*.png"
    config.assets.precompile << "print.css"
    config.assets.precompile << "notify.css"
    config.assets.precompile << "mailers/*.css"
    config.assets.precompile << "graphs/graphs_bundle.js"
    config.assets.precompile << "users/users_bundle.js"
    config.assets.precompile << "network/network_bundle.js"
    config.assets.precompile << "profile/profile_bundle.js"
    config.assets.precompile << "diff_notes/diff_notes_bundle.js"
    config.assets.precompile << "boards/boards_bundle.js"
    config.assets.precompile << "boards/test_utils/simulate_drag.js"
    config.assets.precompile << "blob_edit/blob_edit_bundle.js"
    config.assets.precompile << "snippet/snippet_bundle.js"
    config.assets.precompile << "lib/utils/*.js"
    config.assets.precompile << "lib/*.js"
    config.assets.precompile << "u2f.js"

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    config.action_view.sanitized_allowed_protocols = %w(smb)

    config.middleware.use Rack::Attack

    # Allow access to GitLab API from other domains
    config.middleware.use Rack::Cors do
      allow do
        origins '*'
        resource '/api/*',
          headers: :any,
          methods: :any,
          expose: ['Link']
      end
    end

    # Use Redis caching across all environments
    redis_config_hash = Gitlab::Redis.params
    redis_config_hash[:namespace] = Gitlab::Redis::CACHE_NAMESPACE
    redis_config_hash[:expires_in] = 2.weeks # Cache should not grow forever
    config.cache_store = :redis_store, redis_config_hash

    config.active_record.raise_in_transactional_callbacks = true

    config.active_job.queue_adapter = :sidekiq

    # This is needed for gitlab-shell
    ENV['GITLAB_PATH_OUTSIDE_HOOK'] = ENV['PATH']

    # Gitlab Geo Middleware support
    config.middleware.insert_after ActionDispatch::Flash, 'Gitlab::Middleware::ReadonlyGeo'

    config.generators do |g|
      g.factory_girl false
    end
  end
end

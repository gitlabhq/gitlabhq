require File.expand_path('../boot', __FILE__)

require 'rails/all'
require 'devise'
I18n.config.enforce_available_locales = false
Bundler.require(:default, Rails.env)

module Gitlab
  REDIS_CACHE_NAMESPACE = 'cache:gitlab'

  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths.push(*%W(#{config.root}/lib
                                   #{config.root}/app/models/hooks
                                   #{config.root}/app/models/concerns
                                   #{config.root}/app/models/project_services
                                   #{config.root}/app/models/members))

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
    config.filter_parameters.push(:password, :password_confirmation, :private_token, :otp_attempt, :variables)

    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    # config.active_record.schema_format = :sql

    # Enable the asset pipeline
    config.assets.enabled = true
    config.assets.paths << Gemojione.index.images_path
    config.assets.precompile << "*.png"
    config.assets.precompile << "print.css"

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    config.action_view.sanitized_allowed_protocols = %w(smb)

    # Relative URL support
    # WARNING: We recommend using an FQDN to host GitLab in a root path instead
    # of using a relative URL.
    # Documentation: http://doc.gitlab.com/ce/install/relative_url.html
    # Uncomment and customize the following line to run in a non-root path
    #
    # config.relative_url_root = "/gitlab"

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
    redis_config_file = Rails.root.join('config', 'resque.yml')

    redis_url_string = if File.exists?(redis_config_file)
                         YAML.load_file(redis_config_file)[Rails.env]
                       else
                         "redis://localhost:6379"
                       end

    # Redis::Store does not handle Unix sockets well, so let's do it for them
    redis_config_hash = Redis::Store::Factory.extract_host_options_from_uri(redis_url_string)
    redis_uri = URI.parse(redis_url_string)
    if redis_uri.scheme == 'unix'
      redis_config_hash[:path] = redis_uri.path
    end

    redis_config_hash[:namespace] = REDIS_CACHE_NAMESPACE
    redis_config_hash[:expires_in] = 2.weeks # Cache should not grow forever
    config.cache_store = :redis_store, redis_config_hash

    config.active_record.raise_in_transactional_callbacks = true

    config.active_job.queue_adapter = :sidekiq

    # This is needed for gitlab-shell
    ENV['GITLAB_PATH_OUTSIDE_HOOK'] = ENV['PATH']
  end
end

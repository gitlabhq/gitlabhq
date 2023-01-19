# frozen_string_literal: true
require_relative 'boot'

# Based on https://github.com/rails/rails/blob/v6.0.1/railties/lib/rails/all.rb
# Only load the railties we need instead of loading everything
require 'rails'

require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'action_mailer/railtie'
require 'action_cable/engine'
require 'rails/test_unit/railtie'

Bundler.require(*Rails.groups)

module Gitlab
  class Application < Rails::Application
    config.load_defaults 6.1

    config.active_support.hash_digest_class = ::OpenSSL::Digest::SHA256

    # This section contains configuration from Rails upgrades to override the new defaults so that we
    # keep existing behavior.
    #
    # For boolean values, the new default is the opposite of the value being set in this section.
    # For other types, the new default is noted in the comments. These are also documented in
    # https://guides.rubyonrails.org/configuring.html#results-of-config-load-defaults
    #
    # To switch a setting to the new default value, we just need to delete the specific line here.

    # Rails 6.1
    config.action_dispatch.cookies_same_site_protection = nil # New default is :lax
    ActiveSupport.utc_to_local_returns_utc_offset_times = false
    config.action_controller.urlsafe_csrf_tokens = false
    config.action_view.preload_links_header = false

    # Rails 5.2
    config.action_dispatch.use_authenticated_cookie_encryption = false
    config.active_support.use_authenticated_message_encryption = false
    config.action_controller.default_protect_from_forgery = false
    config.action_view.form_with_generates_ids = false

    # Rails 5.1
    config.assets.unknown_asset_fallback = true

    # Rails 5.0
    config.action_controller.per_form_csrf_tokens = false
    config.action_controller.forgery_protection_origin_check = false
    ActiveSupport.to_time_preserves_timezone = false

    require_dependency Rails.root.join('lib/gitlab')
    require_dependency Rails.root.join('lib/gitlab/utils')
    require_dependency Rails.root.join('lib/gitlab/action_cable/config')
    require_dependency Rails.root.join('lib/gitlab/redis/wrapper')
    require_dependency Rails.root.join('lib/gitlab/redis/cache')
    require_dependency Rails.root.join('lib/gitlab/redis/queues')
    require_dependency Rails.root.join('lib/gitlab/redis/shared_state')
    require_dependency Rails.root.join('lib/gitlab/redis/trace_chunks')
    require_dependency Rails.root.join('lib/gitlab/redis/rate_limiting')
    require_dependency Rails.root.join('lib/gitlab/redis/sessions')
    require_dependency Rails.root.join('lib/gitlab/redis/repository_cache')
    require_dependency Rails.root.join('lib/gitlab/current_settings')
    require_dependency Rails.root.join('lib/gitlab/middleware/read_only')
    require_dependency Rails.root.join('lib/gitlab/middleware/compressed_json')
    require_dependency Rails.root.join('lib/gitlab/middleware/basic_health_check')
    require_dependency Rails.root.join('lib/gitlab/middleware/same_site_cookies')
    require_dependency Rails.root.join('lib/gitlab/middleware/handle_ip_spoof_attack_error')
    require_dependency Rails.root.join('lib/gitlab/middleware/handle_malformed_strings')
    require_dependency Rails.root.join('lib/gitlab/middleware/rack_multipart_tempfile_factory')
    require_dependency Rails.root.join('lib/gitlab/runtime')
    require_dependency Rails.root.join('lib/gitlab/patch/database_config')
    require_dependency Rails.root.join('lib/gitlab/exceptions_app')

    config.exceptions_app = Gitlab::ExceptionsApp.new(Gitlab.jh? ? Rails.root.join('jh/public') : Rails.public_path)

    # This preload is required to:
    #
    # 1. Convert legacy `database.yml`;
    # 2. Include Geo post-deployment migrations settings;
    #
    # TODO: In 15.0, this preload can be wrapped in a Gitlab.ee block
    #       since we don't need to convert legacy `database.yml` anymore.
    config.class.prepend(::Gitlab::Patch::DatabaseConfig)

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
                                     #{config.root}/app/graphql/resolvers/concerns
                                     #{config.root}/app/graphql/mutations/concerns
                                     #{config.root}/app/graphql/types/concerns])

    config.generators.templates.push("#{config.root}/generator_templates")

    foss_eager_load_paths = config.eager_load_paths.dup.freeze
    load_paths = lambda do |dir:|
      ext_paths = foss_eager_load_paths.each_with_object([]) do |path, memo|
        ext_path = config.root.join(dir, Pathname.new(path).relative_path_from(config.root))
        memo << ext_path.to_s
      end

      ext_paths << "#{config.root}/#{dir}/app/replicators"

      # Eager load should load CE first
      config.eager_load_paths.push(*ext_paths)
      config.helpers_paths.push "#{config.root}/#{dir}/app/helpers"

      # Other than Ruby modules we load extensions first
      config.paths['lib/tasks'].unshift "#{config.root}/#{dir}/lib/tasks"
      config.paths['app/views'].unshift "#{config.root}/#{dir}/app/views"
    end

    Gitlab.ee do
      load_paths.call(dir: 'ee')
    end

    Gitlab.jh do
      load_paths.call(dir: 'jh')
    end

    # Rake tasks ignore the eager loading settings, so we need to set the
    # autoload paths explicitly
    config.autoload_paths = config.eager_load_paths.dup

    # These are only used in Rake tasks so we don't need to add these to eager_load_paths
    config.autoload_paths.push("#{config.root}/lib/generators")
    Gitlab.ee { config.autoload_paths.push("#{config.root}/ee/lib/generators") }
    Gitlab.jh { config.autoload_paths.push("#{config.root}/jh/lib/generators") }

    # Add JH initializer into rails initializers path
    Gitlab.jh { config.paths["config/initializers"] << "#{config.root}/jh/config/initializers" }

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    config.i18n.enforce_available_locales = false

    # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
    # the I18n.default_locale when a translation can not be found).
    # We have to explicitly set default locale since 1.1.0 - see:
    # https://github.com/svenfuchs/i18n/pull/415
    config.i18n.fallbacks = [:en]

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
    # - Any parameter ending with `key`
    # - Two-factor tokens (:otp_attempt)
    # - Repo/Project Import URLs (:import_url)
    # - Build traces (:trace)
    # - Build variables (:variables)
    # - GitLab Pages SSL cert/key info (:certificate, :encrypted_key)
    # - Webhook URLs (:hook)
    # - Sentry DSN (:sentry_dsn)
    # - File content from Web Editor (:content)
    # - Jira shared secret (:sharedSecret)
    # - Titles, bodies, and descriptions for notes, issues, etc.
    #
    # NOTE: It is **IMPORTANT** to also update labkit's filter when
    #       adding parameters here to not introduce another security
    #       vulnerability:
    #       https://gitlab.com/gitlab-org/labkit/blob/master/mask/matchers.go
    config.filter_parameters += [
      /token$/,
      /password/,
      /secret/,
      /key$/,
      /^body$/,
      /^description$/,
      /^note$/,
      /^text$/,
      /^title$/,
      /^hook$/
    ]
    config.filter_parameters += %i(
      certificate
      encrypted_key
      import_url
      elasticsearch_url
      elasticsearch_password
      search
      jwt
      mailgun_signing_key
      otp_attempt
      sentry_dsn
      trace
      variables
      content
      sharedSecret
    )

    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    config.active_record.schema_format = :sql

    # Dump all DB schemas even if schema_search_path is defined,
    # so that we get the same db/structure.sql
    # regardless if schema_search_path is set, or not.
    config.active_record.dump_schemas = :all

    # Override default Active Record settings
    # We cannot do this in an initializer because some models are already loaded by then
    config.active_record.cache_versioning = false
    config.active_record.collection_cache_versioning = false
    config.active_record.has_many_inversing = false
    config.active_record.belongs_to_required_by_default = false

    # Enable the asset pipeline
    config.assets.enabled = true

    # Support legacy unicode file named img emojis, `1F939.png`
    config.assets.paths << TanukiEmoji.images_path

    # Import gitlab-svgs directly from vendored directory
    config.assets.paths << "#{config.root}/node_modules/@gitlab/svgs/dist"

    config.assets.paths << "#{config.root}/node_modules/@gitlab/fonts"

    # BEGIN Import path for EE/JH specific SCSS entry point
    # In CE it will import a noop file, in EE a functioning file
    # Order is important, so that the ee file takes precedence:
    if Gitlab.jh?
      config.assets.precompile << "#{config.root}/jh/app/assets/config/jh.js"
      config.assets.paths << "#{config.root}/jh/app/assets"
      config.assets.paths << "#{config.root}/jh/app/assets/stylesheets/_jh"
    end

    if Gitlab.ee?
      config.assets.precompile << "#{config.root}/ee/app/assets/config/ee.js"
      config.assets.paths << "#{config.root}/ee/app/assets"
      config.assets.paths << "#{config.root}/ee/app/assets/stylesheets/_ee"
    end

    config.assets.paths << "#{config.root}/app/assets/stylesheets/_jh"
    config.assets.paths << "#{config.root}/app/assets/stylesheets/_ee"
    # END Import path for EE/JH specific SCSS entry point

    config.assets.paths << "#{config.root}/vendor/assets/javascripts/"

    # This path must come last to avoid confusing sprockets
    # See https://gitlab.com/gitlab-org/gitlab-foss/issues/64091#note_194512508
    config.assets.paths << "#{config.root}/node_modules"

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    # Nokogiri is significantly faster and uses less memory than REXML
    ActiveSupport::XmlMini.backend = 'Nokogiri'

    # This middleware needs to precede ActiveRecord::QueryCache and other middlewares that
    # connect to the database.
    config.middleware.insert_after Rails::Rack::Logger, ::Gitlab::Middleware::BasicHealthCheck

    config.middleware.insert_after Warden::Manager, Rack::Attack

    config.middleware.insert_before ActionDispatch::Cookies, ::Gitlab::Middleware::SameSiteCookies

    config.middleware.insert_before ActionDispatch::RemoteIp, ::Gitlab::Middleware::HandleIpSpoofAttackError

    config.middleware.insert_after ActionDispatch::ActionableExceptions, ::Gitlab::Middleware::HandleMalformedStrings

    config.middleware.insert_after Rack::Sendfile, ::Gitlab::Middleware::RackMultipartTempfileFactory

    config.middleware.insert_before Rack::Runtime, ::Gitlab::Middleware::CompressedJson

    # Allow access to GitLab API from other domains
    config.middleware.insert_before Warden::Manager, Rack::Cors do
      headers_to_expose = %w[Link X-Total X-Total-Pages X-Per-Page X-Page X-Next-Page X-Prev-Page X-Gitlab-Blob-Id X-Gitlab-Commit-Id X-Gitlab-Content-Sha256 X-Gitlab-Encoding X-Gitlab-File-Name X-Gitlab-File-Path X-Gitlab-Last-Commit-Id X-Gitlab-Ref X-Gitlab-Size]

      allow do
        origins Gitlab.config.gitlab.url
        resource '/api/*',
          credentials: true,
          headers: :any,
          methods: :any,
          expose: headers_to_expose
      end

      # Cross-origin requests must not have the session cookie available
      allow do
        origins '*'
        resource '/api/*',
          credentials: false,
          headers: :any,
          methods: :any,
          expose: headers_to_expose
      end

      allow do
        origins { |source, env| source == Gitlab::CurrentSettings.jira_connect_proxy_url }
        resource '/-/jira_connect/oauth_application_id', headers: :any, credentials: false, methods: %i(get options)
      end

      allow do
        origins { |source, env| source == Gitlab::CurrentSettings.jira_connect_proxy_url }
        resource '/-/jira_connect/subscriptions.json', headers: :any, credentials: false, methods: %i(get options)
      end

      allow do
        origins { |source, env| source == Gitlab::CurrentSettings.jira_connect_proxy_url }
        resource '/-/jira_connect/subscriptions/*', headers: :any, credentials: false, methods: %i(delete options)
      end

      # Cross-origin requests must be enabled for the Authorization code with PKCE OAuth flow when used from a browser.
      %w(/oauth/token /oauth/revoke).each do |oauth_path|
        allow do
          origins '*'
          resource oauth_path,
            # These headers are added as defaults to axios.
            # See: https://gitlab.com/gitlab-org/gitlab/-/blob/dd1e70d3676891025534dc4a1e89ca9383178fe7/app/assets/javascripts/lib/utils/axios_utils.js#L8)
            # It's added to declare that this is a XHR request and add the CSRF token without which Rails may reject the request from the frontend.
            headers: %w(Authorization X-CSRF-Token X-Requested-With),
            credentials: false,
            methods: %i(post options)
        end
      end

      # These are routes from doorkeeper-openid_connect:
      # https://github.com/doorkeeper-gem/doorkeeper-openid_connect#routes
      allow do
        origins '*'
        resource '/oauth/userinfo',
          headers: %w(Authorization),
          credentials: false,
          methods: %i(get head post options)
      end

      %w(/oauth/discovery/keys /.well-known/openid-configuration /.well-known/webfinger).each do |openid_path|
        allow do
          origins '*'
          resource openid_path,
          credentials: false,
          methods: %i(get head)
        end
      end
    end

    # Use caching across all environments
    config.cache_store = :redis_cache_store, Gitlab::Redis::Cache.active_support_config

    config.active_job.queue_adapter = :sidekiq
    config.active_job.logger = nil
    config.action_mailer.deliver_later_queue_name = :mailers

    # This is needed for gitlab-shell
    ENV['GITLAB_PATH_OUTSIDE_HOOK'] = ENV['PATH']
    ENV['GIT_TERMINAL_PROMPT'] = '0'

    # GitLab Read-only middleware support
    config.middleware.insert_after ActionDispatch::Flash, ::Gitlab::Middleware::ReadOnly

    config.generators do |g|
      g.factory_bot false
    end

    if defined?(FactoryBotRails)
      config.factory_bot.definition_file_paths << 'ee/spec/factories' if Gitlab.ee?
      config.factory_bot.definition_file_paths << 'jh/spec/factories' if Gitlab.jh?
    end

    # This empty initializer forces the :let_zeitwerk_take_over initializer to run before we load
    # initializers in config/initializers. This is done because autoloading before Zeitwerk takes
    # over is deprecated but our initializers do a lot of autoloading.
    # See https://gitlab.com/gitlab-org/gitlab/issues/197346 for more details
    initializer :move_initializers, before: :load_config_initializers, after: :let_zeitwerk_take_over do
    end

    # We need this for initializers that need to be run before Zeitwerk is loaded
    initializer :before_zeitwerk, before: :let_zeitwerk_take_over, after: :prepend_helpers_path do
      Dir[Rails.root.join('config/initializers_before_autoloader/*.rb')].sort.each do |initializer|
        load_config_initializer(initializer)
      end
    end

    # Add assets for variants of GitLab. They should take precedence over CE.
    # This means if multiple files exist, e.g.:
    #
    # jh/app/assets/stylesheets/example.scss
    # ee/app/assets/stylesheets/example.scss
    # app/assets/stylesheets/example.scss
    #
    # The jh/ version will be preferred.
    initializer :prefer_specialized_assets, after: :append_assets_path, before: :build_middleware_stack do |app|
      Gitlab.extensions.each do |extension|
        %w[images javascripts stylesheets].each do |path|
          app.config.assets.paths.unshift("#{config.root}/#{extension}/app/assets/#{path}")
        end
      end
    end

    # We run the contents of active_record.clear_active_connections again
    # because we connect to database from routes
    # https://github.com/rails/rails/blob/fdf840f69a2e33d78a9d40b91d9b7fddb76711e9/activerecord/lib/active_record/railtie.rb#L308
    initializer :clear_active_connections_again, after: :set_routes_reloader_hook do
      # rubocop:disable Database/MultipleDatabases
      ActiveRecord::Base.clear_active_connections!
      ActiveRecord::Base.flush_idle_connections!
      # rubocop:enable Database/MultipleDatabases
    end

    # DO NOT PLACE ANY INITIALIZERS AFTER THIS.
    config.after_initialize do
      config.active_record.yaml_column_permitted_classes = [
        Symbol, Date, Time,
        BigDecimal, # https://gitlab.com/gitlab-org/gitlab/issues/368846
        Gitlab::Diff::Position,
        # Used in:
        # app/models/concerns/diff_positionable_note.rb
        # app/models/legacy_diff_note.rb:  serialize :st_diff
        ActiveSupport::HashWithIndifferentAccess,
        # Used in ee/lib/ee/api/helpers.rb: send_git_archive
        DeployToken,
        ActiveModel::Attribute.const_get(:FromDatabase, false), # https://gitlab.com/gitlab-org/gitlab/-/issues/368072
        # Used in app/services/web_hooks/log_execution_service.rb: log_execution
        ActiveSupport::TimeWithZone,
        ActiveSupport::TimeZone,
        Gitlab::Color, # https://gitlab.com/gitlab-org/gitlab/-/issues/368844,
        Hashie::Array # https://gitlab.com/gitlab-org/gitlab/-/issues/378089
      ]
      #
      # Restore setting the YAML permitted classes for ActiveRecord
      #
      # In [94d81c3c39e3ddc441c3af3f874e53b197cf3f54][0] rails upstream removed
      # the code that copied the values of
      # config.active_record.yaml_column_permitted_classes to
      # ActiveRecord.yaml_column_permitted_classes during the
      # config.after_initialize stage.
      #
      # We can not move the setting of
      # config.active_record.yaml_column_permitted_classes out of the
      # after_initialize because then the gitlab classes are not loaded yet
      #
      # This change was also ported to the 6.1 branch and released in 6.1.7.
      # Some distributions like Debian even [backported this change to
      # 6.1.6.1][1].
      #
      # This restores the code needed to have gitlab work in those cases.
      #
      # [0]: https://github.com/rails/rails/commit/94d81c3c39e3ddc441c3af3f874e53b197cf3f54
      # [1]: https://salsa.debian.org/ruby-team/rails/-/commit/5663e598b41dc4e2058db22e1ee0d678e5c483ba
      #
      ActiveRecord::Base.yaml_column_permitted_classes = config.active_record.yaml_column_permitted_classes

      # on_master_start yields immediately in unclustered environments and runs
      # when the primary process is done initializing otherwise.
      Gitlab::Cluster::LifecycleEvents.on_master_start do
        Gitlab::Metrics::BootTimeTracker.instance.track_boot_time!
        Gitlab::Console.welcome!
      end
    end
  end
end

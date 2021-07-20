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
    require_dependency Rails.root.join('lib/gitlab')
    require_dependency Rails.root.join('lib/gitlab/utils')
    require_dependency Rails.root.join('lib/gitlab/action_cable/config')
    require_dependency Rails.root.join('lib/gitlab/redis/wrapper')
    require_dependency Rails.root.join('lib/gitlab/redis/cache')
    require_dependency Rails.root.join('lib/gitlab/redis/queues')
    require_dependency Rails.root.join('lib/gitlab/redis/shared_state')
    require_dependency Rails.root.join('lib/gitlab/current_settings')
    require_dependency Rails.root.join('lib/gitlab/middleware/read_only')
    require_dependency Rails.root.join('lib/gitlab/middleware/basic_health_check')
    require_dependency Rails.root.join('lib/gitlab/middleware/same_site_cookies')
    require_dependency Rails.root.join('lib/gitlab/middleware/handle_ip_spoof_attack_error')
    require_dependency Rails.root.join('lib/gitlab/middleware/handle_malformed_strings')
    require_dependency Rails.root.join('lib/gitlab/middleware/rack_multipart_tempfile_factory')
    require_dependency Rails.root.join('lib/gitlab/runtime')

    config.autoloader = :classic

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
    config.autoload_paths.push("#{config.root}/lib/generators")

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

    # Use new connection handling so that we can use Rails 6.1+ multiple
    # database support.
    config.active_record.legacy_connection_handling = false

    config.action_mailer.delivery_job = "ActionMailer::MailDeliveryJob"

    # Enable the asset pipeline
    config.assets.enabled = true

    # Support legacy unicode file named img emojis, `1F939.png`
    config.assets.paths << Gemojione.images_path
    config.assets.paths << "#{config.root}/vendor/assets/fonts"

    config.assets.precompile << "application_utilities.css"
    config.assets.precompile << "application_utilities_dark.css"
    config.assets.precompile << "application_dark.css"

    config.assets.precompile << "startup/*.css"

    config.assets.precompile << "print.css"
    config.assets.precompile << "mailer.css"
    config.assets.precompile << "mailer_client_specific.css"
    config.assets.precompile << "notify.css"
    config.assets.precompile << "mailers/*.css"
    config.assets.precompile << "page_bundles/_mixins_and_variables_and_functions.css"
    config.assets.precompile << "page_bundles/admin/application_settings_metrics_and_profiling.css"
    config.assets.precompile << "page_bundles/admin/jobs_index.css"
    config.assets.precompile << "page_bundles/alert_management_details.css"
    config.assets.precompile << "page_bundles/alert_management_settings.css"
    config.assets.precompile << "page_bundles/boards.css"
    config.assets.precompile << "page_bundles/build.css"
    config.assets.precompile << "page_bundles/ci_status.css"
    config.assets.precompile << "page_bundles/cycle_analytics.css"
    config.assets.precompile << "page_bundles/dev_ops_report.css"
    config.assets.precompile << "page_bundles/environments.css"
    config.assets.precompile << "page_bundles/epics.css"
    config.assets.precompile << "page_bundles/error_tracking_details.css"
    config.assets.precompile << "page_bundles/error_tracking_index.css"
    config.assets.precompile << "page_bundles/group.css"
    config.assets.precompile << "page_bundles/ide.css"
    config.assets.precompile << "page_bundles/import.css"
    config.assets.precompile << "page_bundles/incident_management_list.css"
    config.assets.precompile << "page_bundles/issues_list.css"
    config.assets.precompile << "page_bundles/jira_connect.css"
    config.assets.precompile << "page_bundles/jira_connect_users.css"
    config.assets.precompile << "page_bundles/learn_gitlab.css"
    config.assets.precompile << "page_bundles/members.css"
    config.assets.precompile << "page_bundles/merge_conflicts.css"
    config.assets.precompile << "page_bundles/merge_requests.css"
    config.assets.precompile << "page_bundles/milestone.css"
    config.assets.precompile << "page_bundles/new_namespace.css"
    config.assets.precompile << "page_bundles/oncall_schedules.css"
    config.assets.precompile << "page_bundles/escalation_policies.css"
    config.assets.precompile << "page_bundles/pipeline.css"
    config.assets.precompile << "page_bundles/pipeline_schedules.css"
    config.assets.precompile << "page_bundles/pipelines.css"
    config.assets.precompile << "page_bundles/productivity_analytics.css"
    config.assets.precompile << "page_bundles/profile_two_factor_auth.css"
    config.assets.precompile << "page_bundles/project.css"
    config.assets.precompile << "page_bundles/reports.css"
    config.assets.precompile << "page_bundles/roadmap.css"
    config.assets.precompile << "page_bundles/security_dashboard.css"
    config.assets.precompile << "page_bundles/security_discover.css"
    config.assets.precompile << "page_bundles/signup.css"
    config.assets.precompile << "page_bundles/terminal.css"
    config.assets.precompile << "page_bundles/todos.css"
    config.assets.precompile << "page_bundles/wiki.css"
    config.assets.precompile << "page_bundles/xterm.css"
    config.assets.precompile << "lazy_bundles/cropper.css"
    config.assets.precompile << "lazy_bundles/select2.css"
    config.assets.precompile << "performance_bar.css"
    config.assets.precompile << "disable_animations.css"
    config.assets.precompile << "test_environment.css"
    config.assets.precompile << "snippets.css"
    config.assets.precompile << "locale/**/app.js"
    config.assets.precompile << "emoji_sprites.css"
    config.assets.precompile << "errors.css"
    config.assets.precompile << "jira_connect.js"

    config.assets.precompile << "themes/*.css"

    config.assets.precompile << "highlight/themes/*.css"

    # Import gitlab-svgs directly from vendored directory
    config.assets.paths << "#{config.root}/node_modules/@gitlab/svgs/dist"
    config.assets.precompile << "icons.svg"
    config.assets.precompile << "icons.json"
    config.assets.precompile << "illustrations/*.svg"

    # Import css for xterm
    config.assets.paths << "#{config.root}/node_modules/xterm/src/"
    config.assets.precompile << "xterm.css"

    # Import path for EE specific SCSS entry point
    # In CE it will import a noop file, in EE a functioning file
    # Order is important, so that the ee file takes precedence:
    config.assets.paths << "#{config.root}/ee/app/assets/stylesheets/_ee" if Gitlab.ee?
    config.assets.paths << "#{config.root}/app/assets/stylesheets/_ee"

    config.assets.paths << "#{config.root}/vendor/assets/javascripts/"
    config.assets.precompile << "snowplow/sp.js"

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

      # Cross-origin requests must be enabled for the Authorization code with PKCE OAuth flow when used from a browser.
      %w(/oauth/token /oauth/revoke).each do |oauth_path|
        allow do
          origins '*'
          resource oauth_path,
            headers: %w(Authorization),
            credentials: false,
            methods: %i(post)
        end
      end

      # These are routes from doorkeeper-openid_connect:
      # https://github.com/doorkeeper-gem/doorkeeper-openid_connect#routes
      allow do
        origins '*'
        resource '/oauth/userinfo',
          headers: %w(Authorization),
          credentials: false,
          methods: %i(get head post)
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
    # Full list of options:
    # https://api.rubyonrails.org/classes/ActiveSupport/Cache/RedisCacheStore.html#method-c-new
    caching_config_hash = {}
    caching_config_hash[:redis] = Gitlab::Redis::Cache.pool
    caching_config_hash[:compress] = Gitlab::Utils.to_boolean(ENV.fetch('ENABLE_REDIS_CACHE_COMPRESSION', '1'))
    caching_config_hash[:namespace] = Gitlab::Redis::Cache::CACHE_NAMESPACE
    caching_config_hash[:expires_in] = 2.weeks # Cache should not grow forever

    config.cache_store = :redis_cache_store, caching_config_hash

    config.active_job.queue_adapter = :sidekiq

    # This is needed for gitlab-shell
    ENV['GITLAB_PATH_OUTSIDE_HOOK'] = ENV['PATH']
    ENV['GIT_TERMINAL_PROMPT'] = '0'

    # GitLab Read-only middleware support
    config.middleware.insert_after ActionDispatch::Flash, ::Gitlab::Middleware::ReadOnly

    config.generators do |g|
      g.factory_bot false
    end

    # sprocket-rails adds some precompile assets we actually do not need.
    #
    # It copies all _non_ js and CSS files from the app/assets/ older.
    #
    # In our case this copies for example: Vue, Markdown and Graphql, which we do not need
    # for production.
    #
    # We remove this default behavior and then reimplement it in order to consider ee/ as well
    # and remove those other files we do not need.
    #
    # For reference: https://github.com/rails/sprockets-rails/blob/v3.2.1/lib/sprockets/railtie.rb#L84-L87
    initializer :correct_precompile_targets, after: :set_default_precompile do |app|
      app.config.assets.precompile.reject! { |entry| entry == Sprockets::Railtie::LOOSE_APP_ASSETS }

      # if two files in assets are named the same, it'll likely resolve to the normal app/assets version.
      # See https://gitlab.com/gitlab-jh/gitlab/-/merge_requests/27#note_609101582 for more details
      asset_roots = []

      if Gitlab.jh?
        asset_roots << config.root.join("jh/app/assets").to_s
      end

      asset_roots << config.root.join("app/assets").to_s

      if Gitlab.ee?
        asset_roots << config.root.join("ee/app/assets").to_s
      end

      LOOSE_APP_ASSETS = lambda do |logical_path, filename|
        filename.start_with?(*asset_roots) &&
          !['.js', '.css', '.md', '.vue', '.graphql', ''].include?(File.extname(logical_path))
      end

      app.config.assets.precompile << LOOSE_APP_ASSETS
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
    initializer :prefer_specialized_assets, after: :append_assets_path do |app|
      Gitlab.extensions.each do |extension|
        %w[images javascripts stylesheets].each do |path|
          app.config.assets.paths.unshift("#{config.root}/#{extension}/app/assets/#{path}")
        end
      end
    end
  end
end

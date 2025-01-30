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
require 'sprockets/railtie'

require 'gitlab/utils/all'

Bundler.require(*Rails.groups)

module Gitlab
  class Application < Rails::Application
    config.load_defaults 7.0

    # This section contains configuration from Rails upgrades to override the new defaults so that we
    # keep existing behavior.
    #
    # For boolean values, the new default is the opposite of the value being set in this section.
    # For other types, the new default is noted in the comments. These are also documented in
    # https://guides.rubyonrails.org/configuring.html#results-of-config-load-defaults
    #
    # To switch a setting to the new default value, we just need to delete the specific line here.

    # Rails 7.0
    config.action_controller.raise_on_open_redirects = false
    config.action_dispatch.return_only_request_media_type_on_content_type = true
    config.action_mailer.smtp_timeout = nil # New default is 5
    config.action_view.button_to_generates_button_tag = nil # New default is true
    config.active_record.automatic_scope_inversing = nil # New default is true
    config.active_record.verify_foreign_keys_for_fixtures = nil # New default is true
    config.active_record.partial_inserts = true # New default is false
    config.active_support.executor_around_test_case = nil # New default is true
    config.active_support.isolation_level = nil # New default is thread
    config.active_support.key_generator_hash_digest_class = nil # New default is OpenSSL::Digest::SHA256
    config.active_support.cache_format_version = nil

    # Rails 6.1
    config.action_dispatch.cookies_same_site_protection = nil # New default is :lax
    config.action_view.preload_links_header = false
    ActiveSupport.utc_to_local_returns_utc_offset_times = false

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

    require_dependency Rails.root.join('lib/gitlab')
    require_dependency Rails.root.join('lib/gitlab/action_cable/config')
    require_dependency Rails.root.join('lib/gitlab/redis/wrapper')
    require_dependency Rails.root.join('lib/gitlab/redis/multi_store_wrapper')
    require_dependency Rails.root.join('lib/gitlab/redis/cache')
    require_dependency Rails.root.join('lib/gitlab/redis/queues')
    require_dependency Rails.root.join('lib/gitlab/redis/shared_state')
    require_dependency Rails.root.join('lib/gitlab/redis/trace_chunks')
    require_dependency Rails.root.join('lib/gitlab/redis/rate_limiting')
    require_dependency Rails.root.join('lib/gitlab/redis/sessions')
    require_dependency Rails.root.join('lib/gitlab/redis/repository_cache')
    require_dependency Rails.root.join('lib/gitlab/redis/db_load_balancing')
    require_dependency Rails.root.join('lib/gitlab/current_settings')
    require_dependency Rails.root.join('lib/gitlab/middleware/read_only')
    require_dependency Rails.root.join('lib/gitlab/middleware/compressed_json')
    require_dependency Rails.root.join('lib/gitlab/middleware/basic_health_check')
    require_dependency Rails.root.join('lib/gitlab/middleware/same_site_cookies')
    require_dependency Rails.root.join('lib/gitlab/middleware/handle_ip_spoof_attack_error')
    require_dependency Rails.root.join('lib/gitlab/middleware/handle_malformed_strings')
    require_dependency Rails.root.join('lib/gitlab/middleware/path_traversal_check')
    require_dependency Rails.root.join('lib/gitlab/middleware/rack_multipart_tempfile_factory')
    require_dependency Rails.root.join('lib/gitlab/runtime')
    require_dependency Rails.root.join('lib/gitlab/patch/database_config')
    require_dependency Rails.root.join('lib/gitlab/patch/redis_cache_store')
    require_dependency Rails.root.join('lib/gitlab/patch/old_redis_cache_store')
    require_dependency Rails.root.join('lib/gitlab/exceptions_app')

    unless ::Gitlab.next_rails?
      config.active_support.disable_to_s_conversion = false # New default is true
      config.active_support.use_rfc4122_namespaced_uuids = true
      ActiveSupport.to_time_preserves_timezone = false
    end

    config.exceptions_app = Gitlab::ExceptionsApp.new(Gitlab.jh? ? Rails.root.join('jh/public') : Rails.public_path)

    # This preload is required to:
    #
    # 1. Support providing sensitive DB configuration through an external script;
    # 2. Include Geo post-deployment migrations settings;
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

    foss_eager_load_paths =
      if Gitlab.next_rails?
        config.all_eager_load_paths.dup.freeze
      else
        config.eager_load_paths.dup.freeze
      end

    load_paths = ->(dir:) do
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

    # Add EE/JH initializer into rails initializers path
    Gitlab.ee { config.paths["config/initializers"] << "#{config.root}/ee/config/initializers" }
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
    # - Any parameter named `redirect`, filtered for security concerns of exposing sensitive information
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
      /token$/i,
      /password/,
      /secret/,
      /key$/,
      /^body$/,
      /^description$/,
      /^query$/,
      /^note$/,
      /^text$/,
      /^title$/,
      /^hook$/
    ]
    config.filter_parameters += %i[
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
      redirect
      question
      SAMLResponse
      selectedText
    ]

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

    # Disable adding field_with_errors wrapper to form elements
    config.action_view.field_error_proc = proc { |html_tag, instance| html_tag }

    # Support legacy unicode file named img emojis, `1F939.png`
    config.assets.paths << TanukiEmoji.images_path
    config.assets.paths << "#{config.root}/vendor/assets/fonts"

    config.assets.precompile << "application_utilities.css"
    config.assets.precompile << "application_utilities_dark.css"
    config.assets.precompile << "application_dark.css"
    config.assets.precompile << "tailwind.css"

    config.assets.precompile << "print.css"
    config.assets.precompile << "mailers/highlighted_diff_email.css"
    config.assets.precompile << "mailers/mailer.css"
    config.assets.precompile << "mailers/mailer_client_specific.css"
    config.assets.precompile << "mailers/notify.css"
    config.assets.precompile << "mailers/notify_enhanced.css"
    config.assets.precompile << "page_bundles/_mixins_and_variables_and_functions.css"
    config.assets.precompile << "page_bundles/admin/elasticsearch_form.css"
    config.assets.precompile << "page_bundles/admin/geo_replicable.css"
    config.assets.precompile << "page_bundles/admin/geo_sites.css"
    config.assets.precompile << "page_bundles/alert_management_details.css"
    config.assets.precompile << "page_bundles/alert_management_settings.css"
    config.assets.precompile << "page_bundles/billings.css"
    config.assets.precompile << "page_bundles/boards.css"
    config.assets.precompile << "page_bundles/branches.css"
    config.assets.precompile << "page_bundles/build.css"
    config.assets.precompile << "page_bundles/ci_status.css"
    config.assets.precompile << "page_bundles/cluster_agents.css"
    config.assets.precompile << "page_bundles/clusters.css"
    config.assets.precompile << "page_bundles/commit_description.css"
    config.assets.precompile << "page_bundles/commit_rapid_diffs.css"
    config.assets.precompile << "page_bundles/commits.css"
    config.assets.precompile << "page_bundles/cycle_analytics.css"
    config.assets.precompile << "page_bundles/dashboard.css"
    config.assets.precompile << "page_bundles/dashboard_projects.css"
    config.assets.precompile << "page_bundles/design_management.css"
    config.assets.precompile << "page_bundles/dev_ops_reports.css"
    config.assets.precompile << "page_bundles/editor.css"
    config.assets.precompile << "page_bundles/environments.css"
    config.assets.precompile << "page_bundles/epics.css"
    config.assets.precompile << "page_bundles/error_tracking_details.css"
    config.assets.precompile << "page_bundles/escalation_policies.css"
    config.assets.precompile << "page_bundles/graph_charts.css"
    config.assets.precompile << "page_bundles/graphql_explorer.css"
    config.assets.precompile << "page_bundles/group.css"
    config.assets.precompile << "page_bundles/ide.css"
    config.assets.precompile << "page_bundles/import.css"
    config.assets.precompile << "page_bundles/incidents.css"
    config.assets.precompile << "page_bundles/issuable.css"
    config.assets.precompile << "page_bundles/issuable_list.css"
    config.assets.precompile << "page_bundles/issues_analytics.css"
    config.assets.precompile << "page_bundles/issues_list.css"
    config.assets.precompile << "page_bundles/issues_show.css"
    config.assets.precompile << "page_bundles/jira_connect.css"
    config.assets.precompile << "page_bundles/labels.css"
    config.assets.precompile << "page_bundles/log_viewer.css"
    config.assets.precompile << "page_bundles/login.css"
    config.assets.precompile << "page_bundles/members.css"
    config.assets.precompile << "page_bundles/merge_conflicts.css"
    config.assets.precompile << "page_bundles/merge_request.css"
    config.assets.precompile << "page_bundles/merge_request_analytics.css"
    config.assets.precompile << "page_bundles/merge_request_rapid_diffs.css"
    config.assets.precompile << "page_bundles/merge_requests.css"
    config.assets.precompile << "page_bundles/milestone.css"
    config.assets.precompile << "page_bundles/ml_experiment_tracking.css"
    config.assets.precompile << "page_bundles/new_namespace.css"
    config.assets.precompile << "page_bundles/notes_shared.css"
    config.assets.precompile << "page_bundles/oncall_schedules.css"
    config.assets.precompile << "page_bundles/operations.css"
    config.assets.precompile << "page_bundles/organizations.css"
    config.assets.precompile << "page_bundles/paginated_table.css"
    config.assets.precompile << "page_bundles/pipeline.css"
    config.assets.precompile << "page_bundles/pipeline_editor.css"
    config.assets.precompile << "page_bundles/pipelines.css"
    config.assets.precompile << "page_bundles/profile.css"
    config.assets.precompile << "page_bundles/profile_two_factor_auth.css"
    config.assets.precompile << "page_bundles/profiles/preferences.css"
    config.assets.precompile << "page_bundles/project.css"
    config.assets.precompile << "page_bundles/projects.css"
    config.assets.precompile << "page_bundles/projects_edit.css"
    config.assets.precompile << "page_bundles/promotions.css"
    config.assets.precompile << "page_bundles/releases.css"
    config.assets.precompile << "page_bundles/remote_development.css"
    config.assets.precompile << "page_bundles/reports.css"
    config.assets.precompile << "page_bundles/requirements.css"
    config.assets.precompile << "page_bundles/roadmap.css"
    config.assets.precompile << "page_bundles/runner_details.css"
    config.assets.precompile << "page_bundles/runners.css"
    config.assets.precompile << "page_bundles/search.css"
    config.assets.precompile << "page_bundles/security_dashboard.css"
    config.assets.precompile << "page_bundles/settings.css"
    config.assets.precompile << "page_bundles/signup.css"
    config.assets.precompile << "page_bundles/terminal.css"
    config.assets.precompile << "page_bundles/terms.css"
    config.assets.precompile << "page_bundles/todos.css"
    config.assets.precompile << "page_bundles/tree.css"
    config.assets.precompile << "page_bundles/users.css"
    config.assets.precompile << "page_bundles/web_ide_loader.css"
    config.assets.precompile << "page_bundles/wiki.css"
    config.assets.precompile << "page_bundles/work_items.css"
    config.assets.precompile << "page_bundles/xterm.css"
    config.assets.precompile << "lazy_bundles/cropper.css"
    config.assets.precompile << "lazy_bundles/gridstack.css"
    config.assets.precompile << "performance_bar.css"
    config.assets.precompile << "disable_animations.css"
    config.assets.precompile << "test_environment.css"
    config.assets.precompile << "snippets.css"
    config.assets.precompile << "fonts.css"
    config.assets.precompile << "locale/**/app.js"
    config.assets.precompile << "emoji_sprites.css"
    config.assets.precompile << "errors.css"
    config.assets.precompile << "jira_connect.js"

    config.assets.precompile << "themes/*.css"

    config.assets.precompile << "highlight/themes/*.css"
    config.assets.precompile << "highlight/diff_custom_colors_addition.css"
    config.assets.precompile << "highlight/diff_custom_colors_deletion.css"

    # Import woff2 for fonts
    config.assets.paths << "#{config.root}/node_modules/@gitlab/fonts/"
    config.assets.precompile << "gitlab-sans/*.woff2"
    config.assets.precompile << "gitlab-mono/*.woff2"

    # Import gitlab-svgs directly from vendored directory
    config.assets.paths << "#{config.root}/node_modules/@gitlab/svgs/dist"
    config.assets.paths << "#{config.root}/node_modules/@jihulab/svgs/dist" if Gitlab.jh?
    config.assets.precompile << "illustrations/jh/*.svg" if Gitlab.jh?
    config.assets.precompile << "icons.svg"
    config.assets.precompile << "icons.json"
    config.assets.precompile << "file_icons/file_icons.svg"
    config.assets.precompile << "file_icons/file_icons.json"
    config.assets.precompile << "illustrations/*.svg"
    config.assets.precompile << "illustrations/*.png"

    # Import path for EE specific SCSS entry point
    # In CE it will import a noop file, in EE a functioning file
    # Order is important, so that the ee file takes precedence:
    config.assets.paths << "#{config.root}/jh/app/assets/stylesheets/_jh" if Gitlab.jh?
    config.assets.paths << "#{config.root}/ee/app/assets/stylesheets/_ee" if Gitlab.ee?
    config.assets.paths << "#{config.root}/app/assets/stylesheets/_jh"
    config.assets.paths << "#{config.root}/app/assets/stylesheets/_ee"

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

    config.middleware.insert_after ActionDispatch::ShowExceptions, ::Gitlab::Middleware::HandleMalformedStrings

    config.middleware.insert_after ::Gitlab::Middleware::HandleMalformedStrings, ::Gitlab::Middleware::PathTraversalCheck

    config.middleware.insert_after Rack::Sendfile, ::Gitlab::Middleware::RackMultipartTempfileFactory

    config.middleware.insert_before Rack::Runtime, ::Gitlab::Middleware::CompressedJson

    # Allow access to GitLab API from other domains
    config.middleware.insert_before Warden::Manager, Rack::Cors do
      headers_to_expose = %w[Link X-Total X-Total-Pages X-Per-Page X-Page X-Next-Page X-Prev-Page X-Gitlab-Blob-Id X-Gitlab-Commit-Id X-Gitlab-Content-Sha256 X-Gitlab-Encoding X-Gitlab-File-Name X-Gitlab-File-Path X-Gitlab-Last-Commit-Id X-Gitlab-Ref X-Gitlab-Size X-Request-Id ETag]

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
        resource '/-/jira_connect/oauth_application_id', headers: :any, credentials: false, methods: %i[get options]
      end

      allow do
        origins { |source, env| source == Gitlab::CurrentSettings.jira_connect_proxy_url }
        resource '/-/jira_connect/subscriptions.json', headers: :any, credentials: false, methods: %i[get options]
      end

      allow do
        origins { |source, env| source == Gitlab::CurrentSettings.jira_connect_proxy_url }
        resource '/-/jira_connect/subscriptions/*', headers: :any, credentials: false, methods: %i[delete options]
      end

      # Cross-origin requests must be enabled for the Authorization code with PKCE OAuth flow when used from a browser.
      %w[/oauth/token /oauth/revoke].each do |oauth_path|
        allow do
          origins '*'
          resource oauth_path,
            # These headers are added as defaults to axios.
            # See: https://gitlab.com/gitlab-org/gitlab/-/blob/dd1e70d3676891025534dc4a1e89ca9383178fe7/app/assets/javascripts/lib/utils/axios_utils.js#L8)
            # It's added to declare that this is a XHR request and add the CSRF token without which Rails may reject the request from the frontend.
            headers: %w[Authorization X-CSRF-Token X-Requested-With],
            credentials: false,
            methods: %i[post options]
        end
      end

      allow do
        origins '*'
        resource '/oauth/token/info',
          headers: %w[Authorization],
          credentials: false,
          methods: %i[get head options]
      end

      # These are routes from doorkeeper-openid_connect:
      # https://github.com/doorkeeper-gem/doorkeeper-openid_connect#routes
      allow do
        origins '*'
        resource '/oauth/userinfo',
          headers: %w[Authorization],
          credentials: false,
          methods: %i[get head post options]
      end

      %w[/oauth/discovery/keys /.well-known/openid-configuration /.well-known/webfinger].each do |openid_path|
        allow do
          origins '*'
          resource openid_path,
            credentials: false,
            methods: %i[get head]
        end
      end

      # Allow assets to be loaded to web-ide
      # https://gitlab.com/gitlab-org/gitlab/-/issues/421177
      allow do
        origins 'https://*.web-ide.gitlab-static.net'
        resource '/assets/webpack/*',
          credentials: false,
          methods: %i[get head]
      end
    end

    # Use caching across all environments
    if ::Gitlab.next_rails?
      ActiveSupport::Cache::RedisCacheStore.prepend(Gitlab::Patch::RedisCacheStore)
    else
      ActiveSupport::Cache::RedisCacheStore.prepend(Gitlab::Patch::OldRedisCacheStore)
    end

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

    # sprocket-rails adds some precompile assets we actually do not need.
    #
    # It copies all _non_ js and CSS files from the app/assets/ folder.
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

      LOOSE_APP_ASSETS = ->(logical_path, filename) do
        filename.start_with?(*asset_roots) &&
          ['.js', '.css', '.md', '.vue', '.graphql', ''].exclude?(File.extname(logical_path))
      end

      app.config.assets.precompile << LOOSE_APP_ASSETS
    end

    # This empty initializer forces the :setup_main_autoloader initializer to run before we load
    # initializers in config/initializers. This is done because autoloading before Zeitwerk takes
    # over is deprecated but our initializers do a lot of autoloading.
    # See https://gitlab.com/gitlab-org/gitlab/issues/197346 for more details
    initializer :move_initializers, before: :load_config_initializers, after: :setup_main_autoloader do
    end

    # We need this for initializers that need to be run before Zeitwerk is loaded
    initializer :before_zeitwerk, before: :setup_main_autoloader, after: :prepend_helpers_path do
      Dir[Rails.root.join('config/initializers_before_autoloader/*.rb')].each do |initializer|
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

    # Add `app/assets/builds` as the highest precedence to find assets
    initializer :add_cssbundling_output_dir, after: :prefer_specialized_assets do |app|
      app.config.assets.paths.unshift("#{config.root}/app/assets/builds")
    end

    # We run the contents of active_record.clear_active_connections again
    # because we connect to database from routes
    # https://github.com/rails/rails/blob/fdf840f69a2e33d78a9d40b91d9b7fddb76711e9/activerecord/lib/active_record/railtie.rb#L308
    initializer :clear_active_connections_again, after: :set_routes_reloader_hook do
      # rubocop:disable Database/MultipleDatabases
      ActiveRecord::Base.connection_handler.clear_active_connections!(ActiveRecord::Base.current_role)
      ActiveRecord::Base.connection_handler.flush_idle_connections!(ActiveRecord::Base.current_role)
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
        ActiveSupport::SafeBuffer,
        Gitlab::Color, # https://gitlab.com/gitlab-org/gitlab/-/issues/368844,
        Hashie::Array, # https://gitlab.com/gitlab-org/gitlab/-/issues/378089
        Hashie::Mash # https://gitlab.com/gitlab-org/gitlab/-/issues/440316
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
      ActiveRecord.yaml_column_permitted_classes = config.active_record.yaml_column_permitted_classes

      # on_master_start yields immediately in unclustered environments and runs
      # when the primary process is done initializing otherwise.
      Gitlab::Cluster::LifecycleEvents.on_master_start do
        Gitlab::Metrics::BootTimeTracker.instance.track_boot_time!
        Gitlab::Console.welcome!
      end
    end
  end
end

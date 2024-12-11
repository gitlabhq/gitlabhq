# frozen_string_literal: true

require 'gitlab/middleware/strip_cookies'
require 'gitlab/testing/request_blocker_middleware'
require 'gitlab/testing/robots_blocker_middleware'
require 'gitlab/testing/request_inspector_middleware'
require 'gitlab/testing/clear_process_memory_cache_middleware'
require 'gitlab/testing/action_cable_blocker'
require 'gitlab/utils/all'

Rails.application.configure do
  # Make sure the middleware is inserted first in middleware chain
  config.middleware.insert_before(ActionDispatch::Static, Gitlab::Testing::RequestBlockerMiddleware)
  config.middleware.insert_before(ActionDispatch::Static, Gitlab::Testing::RobotsBlockerMiddleware)
  config.middleware.insert_before(ActionDispatch::Static, Gitlab::Testing::RequestInspectorMiddleware)
  config.middleware.insert_before(ActionDispatch::Static, Gitlab::Testing::ClearProcessMemoryCacheMiddleware)
  config.middleware.insert_before(ActionDispatch::Cookies, Gitlab::Middleware::StripCookies, paths: [%r{^/assets/}])

  Gitlab::Testing::ActionCableBlocker.install

  # Settings specified here will take precedence over those in config/application.rb

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = Gitlab::Utils.to_boolean(ENV['CACHE_CLASSES'], default: false)

  config.view_component.preview_route = "/-/view_component/previews"

  # Configure static asset server for tests with Cache-Control for performance
  config.assets.compile = false if ENV['CI']
  # There is no need to check if assets are precompiled locally
  # To debug AssetNotPrecompiled errors locally, set CHECK_PRECOMPILED_ASSETS to true
  config.assets.check_precompiled_asset = Gitlab::Utils.to_boolean(ENV['CHECK_PRECOMPILED_ASSETS'], default: false)

  config.public_file_server.enabled = true
  config.public_file_server.headers = { 'Cache-Control' => 'public, max-age=3600' }

  # Show full error reports and disable caching
  config.active_record.verbose_query_logs  = true
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment
  config.action_controller.allow_forgery_protection = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  if ::Gitlab.next_rails?
    config.action_mailer.preview_paths = [GitlabEdition.path_glob('app/mailers/previews')]
  else
    config.action_mailer.preview_path = GitlabEdition.path_glob('app/mailers/previews')
  end

  config.eager_load = Gitlab::Utils.to_boolean(ENV['GITLAB_TEST_EAGER_LOAD'], default: ENV['CI'].present?)

  config.cache_store = :null_store

  config.active_job.queue_adapter = :test

  if ENV['CI'] && !ENV['RAILS_ENABLE_TEST_LOG']
    config.logger = ActiveSupport::TaggedLogging.new(Logger.new(nil))
    config.log_level = :fatal
  end
end

Rails.application.configure do
  # Make sure the middleware is inserted first in middleware chain
  config.middleware.insert_before('ActionDispatch::Static', 'Gitlab::Testing::RequestBlockerMiddleware')
  config.middleware.insert_before('ActionDispatch::Static', 'Gitlab::Testing::RequestInspectorMiddleware')

  # Settings specified here will take precedence over those in config/application.rb

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!

  # Enabling caching of classes slows start-up time because all controllers
  # are loaded at initalization, but it reduces memory and load because files
  # are not reloaded with every request. For example, caching is not necessary
  # for loading database migrations but useful for handling Knapsack specs.
  config.cache_classes = ENV['CACHE_CLASSES'] == 'true'

  # Configure static asset server for tests with Cache-Control for performance
  config.assets.compile = false if ENV['CI']

  if Gitlab.rails5?
    config.public_file_server.enabled = true
  else
    config.serve_static_files = true
  end

  config.static_cache_control = "public, max-age=3600"

  # Show full error reports and disable caching
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

  # Print deprecation notices to the stderr
  config.active_support.deprecation = :stderr

  config.eager_load = false

  config.cache_store = :null_store

  config.active_job.queue_adapter = :test

  if ENV['CI'] && !ENV['RAILS_ENABLE_TEST_LOG']
    config.logger = ActiveSupport::TaggedLogging.new(Logger.new(nil))
    config.log_level = :fatal
  end
end

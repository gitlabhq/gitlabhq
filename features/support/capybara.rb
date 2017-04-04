require 'capybara/poltergeist'
require 'capybara-screenshot/spinach'

# Give CI some extra time
timeout = (ENV['CI'] || ENV['CI_SERVER']) ? 60 : 30

Capybara.javascript_driver = :poltergeist
Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(
    app,
    js_errors: true,
    timeout: timeout,
    window_size: [1366, 768],
    phantomjs_options: [
      '--load-images=no'
    ]
  )
end

Capybara.default_max_wait_time = timeout
Capybara.ignore_hidden_elements = false

# Keep only the screenshots generated from the last failing test suite
Capybara::Screenshot.prune_strategy = :keep_last_run

Spinach.hooks.before_run do
  TestEnv.eager_load_driver_server
end

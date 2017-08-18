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
    url_whitelist: %w[localhost 127.0.0.1],
    url_blacklist: %w[.mp4 .png .gif .avi .bmp .jpg .jpeg],
    phantomjs_options: [
      '--load-images=yes'
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

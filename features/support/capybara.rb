require 'capybara-screenshot/spinach'

# Give CI some extra time
timeout = (ENV['CI'] || ENV['CI_SERVER']) ? 60 : 30

Capybara.javascript_driver = :chrome
Capybara.register_driver :chrome do |app|
  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    'chromeOptions' => {
      'args' => %w[headless no-sandbox disable-gpu]
    }
  )

  Capybara::Selenium::Driver
    .new(app, browser: :chrome, desired_capabilities: capabilities)
end

Capybara.default_max_wait_time = timeout
Capybara.ignore_hidden_elements = false

# Keep only the screenshots generated from the last failing test suite
Capybara::Screenshot.prune_strategy = :keep_last_run

Spinach.hooks.before_run do
  TestEnv.eager_load_driver_server
end

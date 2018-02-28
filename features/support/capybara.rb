require 'capybara-screenshot/spinach'

# Give CI some extra time
timeout = (ENV['CI'] || ENV['CI_SERVER']) ? 60 : 30

Capybara.javascript_driver = :chrome
Capybara.register_driver :chrome do |app|
  extra_args = []
  extra_args << 'headless' unless ENV['CHROME_HEADLESS'] =~ /^(false|no|0)$/i

  capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
    chromeOptions: {
      'args' => %w[no-sandbox disable-gpu --window-size=1240,1400] + extra_args
    }
  )

  Capybara::Selenium::Driver
    .new(app, browser: :chrome, desired_capabilities: capabilities)
end

Capybara.default_max_wait_time = timeout
Capybara.ignore_hidden_elements = false

# Keep only the screenshots generated from the last failing test suite
Capybara::Screenshot.prune_strategy = :keep_last_run
# From https://github.com/mattheworiordan/capybara-screenshot/issues/84#issuecomment-41219326
Capybara::Screenshot.register_driver(:chrome) do |driver, path|
  driver.browser.save_screenshot(path)
end

Spinach.hooks.before_run do
  TestEnv.eager_load_driver_server
end

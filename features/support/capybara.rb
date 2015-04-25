require 'spinach/capybara'
require 'capybara/poltergeist'

Capybara.javascript_driver = :poltergeist
Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, js_errors: false, timeout: 90)
end

Spinach.hooks.on_tag("javascript") do
  Capybara.current_driver = Capybara.javascript_driver
end

Capybara.default_wait_time = 60
Capybara.ignore_hidden_elements = false

require 'capybara-screenshot/spinach'

# Keep only the screenshots generated from the last failing test suite
Capybara::Screenshot.prune_strategy = :keep_last_run

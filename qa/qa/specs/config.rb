require 'rspec/core'
require 'capybara/rspec'
require 'capybara-screenshot/rspec'
require 'selenium-webdriver'

# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/LineLength

module QA
  module Specs
    class Config < Scenario::Template
      attr_writer :address

      def initialize
        @address = ENV['GITLAB_URL']
      end

      def perform
        raise 'Please configure GitLab address!' unless @address

        configure_rspec!
        configure_capybara!
      end

      def configure_rspec!
        RSpec.configure do |config|
          config.expect_with :rspec do |expectations|
            expectations.include_chain_clauses_in_custom_matcher_descriptions = true
          end

          config.mock_with :rspec do |mocks|
            mocks.verify_partial_doubles = true
          end

          config.order = :random
          Kernel.srand config.seed
          config.formatter = :documentation
          config.color = true
        end
      end

      def configure_capybara!
        Capybara.register_driver :chrome do |app|
          capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
            'chromeOptions' => {
              'binary' => '/usr/bin/google-chrome-stable',
              'args' => %w[headless no-sandbox disable-gpu window-size=1280,1024]
            }
          )

          Capybara::Selenium::Driver
            .new(app, browser: :chrome, desired_capabilities: capabilities)
        end

        Capybara::Screenshot.register_driver(:chrome) do |driver, path|
          driver.browser.save_screenshot(path)
        end

        Capybara.configure do |config|
          config.app_host = @address
          config.default_driver = :chrome
          config.javascript_driver = :chrome
          config.default_max_wait_time = 4

          # https://github.com/mattheworiordan/capybara-screenshot/issues/164
          config.save_path = 'tmp'
        end
      end
    end
  end
end

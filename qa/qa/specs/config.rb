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
            # This option will default to `true` in RSpec 4. It makes the `description`
            # and `failure_message` of custom matchers include text for helper methods
            # defined using `chain`.
            expectations.include_chain_clauses_in_custom_matcher_descriptions = true
          end

          config.mock_with :rspec do |mocks|
            # Prevents you from mocking or stubbing a method that does not exist on
            # a real object. This is generally recommended, and will default to
            # `true` in RSpec 4.
            mocks.verify_partial_doubles = true
          end

          # Run specs in random order to surface order dependencies.
          config.order = :random
          Kernel.srand config.seed

          # config.before(:all) do
          #   page.current_window.resize_to(1200, 1800)
          # end

          config.formatter = :documentation
          config.color = true
        end
      end

      def configure_capybara!
        Capybara.register_driver :chrome do |app|
          capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
            'chromeOptions' => {
              'binary' => '/opt/google/chrome-beta/google-chrome-beta',
              'args' => %w[headless no-sandbox disable-gpu]
            }
          )

          Capybara::Selenium::Driver
            .new(app, browser: :chrome, desired_capabilities: capabilities)
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

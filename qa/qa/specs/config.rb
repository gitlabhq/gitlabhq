require 'rspec/core'
require 'capybara/rspec'
require 'capybara-webkit'
require 'capybara-screenshot/rspec'

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
        configure_webkit!
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

          config.before(:all) do
            page.current_window.resize_to(1200, 1800)
          end

          config.formatter = :documentation
          config.color = true
        end
      end

      def configure_capybara!
        Capybara.configure do |config|
          config.app_host = @address
          config.default_driver = :webkit
          config.javascript_driver = :webkit
          config.default_max_wait_time = 4

          # https://github.com/mattheworiordan/capybara-screenshot/issues/164
          config.save_path = 'tmp'
        end
      end

      def configure_webkit!
        Capybara::Webkit.configure do |config|
          config.allow_url(@address)
          config.block_unknown_urls
        end
      rescue RuntimeError # rubocop:disable Lint/HandleExceptions
        # TODO, Webkit is already configured, this make this
        # configuration step idempotent, should be improved.
      end
    end
  end
end

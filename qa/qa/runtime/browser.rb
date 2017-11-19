require 'rspec/core'
require 'capybara/rspec'
require 'capybara-screenshot/rspec'
require 'selenium-webdriver'

module QA
  module Runtime
    class Browser
      include Scenario::Actable

      def initialize
        self.class.configure!
      end

      def visit(page, &block)
        Browser::Session.new(page).tap do |session|
          session.perform(&block)
        end
      end

      def self.visit(page, &block)
        new.visit(page, &block)
      end

      def self.configure!
        return if Capybara.drivers.include?(:chrome)

        Capybara.register_driver :chrome do |app|
          capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
            'chromeOptions' => {
              'args' => %w[headless no-sandbox disable-gpu window-size=1280,1680]
            }
          )

          Capybara::Selenium::Driver
            .new(app, browser: :chrome, desired_capabilities: capabilities)
        end

        Capybara::Screenshot.register_driver(:chrome) do |driver, path|
          driver.browser.save_screenshot(path)
        end

        Capybara.configure do |config|
          config.default_driver = :chrome
          config.javascript_driver = :chrome
          config.default_max_wait_time = 4
          # https://github.com/mattheworiordan/capybara-screenshot/issues/164
          config.save_path = 'tmp'
        end
      end

      class Session
        include Capybara::DSL

        attr_reader :address

        def initialize(page)
          @address = page.is_a?(String) ? page : page.address
        end

        def perform(&block)
          visit(@address)

          block.call if block_given?
        rescue
          # RSpec examples will take care of screenshots on their own
          #
          unless block.binding.receiver.class < RSpec::Core::ExampleGroup
            Capybara::Screenshot.screenshot_and_save_page
          end

          raise
        ensure
          clear! if block_given?
        end

        ##
        # Selenium allows to reset session cookies for current domain only.
        #
        # See gitlab-org/gitlab-qa#102
        #
        def clear!
          visit(@address)
          Capybara.reset_session!
        end
      end
    end
  end
end

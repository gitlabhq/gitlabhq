require 'rspec/core'
require 'capybara/rspec'
require 'capybara-screenshot/rspec'
require 'selenium-webdriver'

module QA
  module Runtime
    module Browser
      extend self

      def visit(entry, &block)
        address = entry.is_a?(String) ? entry : entry.address

        configure!
        page.visit(address)

        if block_given?
          block.call(page)

          page.visit(address)
          reset_domain_session!
        end
      rescue
        # RSpec examples will take care of screenshots on their own
        #
        unless block.binding.receiver.class < RSpec::Core::ExampleGroup
          Capybara::Screenshot.screenshot_and_save_page
        end

        raise
      end

      ##
      # Current session, when Capybara::DSL is included `page` method is
      # mixed in as well.
      #
      def page
        Capybara.current_session
      end

      def reset_domain_session(address)
        ##
        # Selenium allows to reset session cookies for current domain only.
        #
        # See gitlab-org/gitlab-qa#102
        #
        Capybar.reset_session!
      end

      def configure!
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
    end
  end
end

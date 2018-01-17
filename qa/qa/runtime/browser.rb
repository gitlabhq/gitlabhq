require 'rspec/core'
require 'capybara/rspec'
require 'capybara-screenshot/rspec'
require 'selenium-webdriver'

module QA
  module Runtime
    class Browser
      include QA::Scenario::Actable

      def initialize
        self.class.configure!
      end

      ##
      # Visit a page that belongs to a GitLab instance under given address.
      #
      # Example:
      #
      # visit(:gitlab, Page::Main::Login)
      # visit('http://gitlab.example/users/sign_in')
      #
      # In case of an address that is a symbol we will try to guess address
      # based on `Runtime::Scenario#something_address`.
      #
      def visit(address, page, &block)
        Browser::Session.new(address, page).tap do |session|
          session.perform(&block)
        end
      end

      def self.visit(address, page, &block)
        new.visit(address, page, &block)
      end

      def self.configure!
        return if Capybara.drivers.include?(:chrome)

        Capybara.register_driver :chrome do |app|
          capabilities = Selenium::WebDriver::Remote::Capabilities.chrome(
            # This enables access to logs with `page.driver.manage.get_log(:browser)`
            loggingPrefs: {
              browser: "ALL",
              client: "ALL",
              driver: "ALL",
              server: "ALL"
            }
          )

          options = Selenium::WebDriver::Chrome::Options.new
          options.add_argument("window-size=1240,1680")

          # Chrome won't work properly in a Docker container in sandbox mode
          options.add_argument("no-sandbox")

          # Run headless by default unless CHROME_HEADLESS is false
          if QA::Runtime::Env.chrome_headless?
            options.add_argument("headless")

            # Chrome documentation says this flag is needed for now
            # https://developers.google.com/web/updates/2017/04/headless-chrome#cli
            options.add_argument("disable-gpu")
          end

          # Disable /dev/shm use in CI. See https://gitlab.com/gitlab-org/gitlab-ee/issues/4252
          options.add_argument("disable-dev-shm-usage") if QA::Runtime::Env.running_in_ci?

          Capybara::Selenium::Driver.new(
            app,
            browser: :chrome,
            desired_capabilities: capabilities,
            options: options
          )
        end

        # Keep only the screenshots generated from the last failing test suite
        Capybara::Screenshot.prune_strategy = :keep_last_run

        # From https://github.com/mattheworiordan/capybara-screenshot/issues/84#issuecomment-41219326
        Capybara::Screenshot.register_driver(:chrome) do |driver, path|
          driver.browser.save_screenshot(path)
        end

        Capybara.configure do |config|
          config.default_driver = :chrome
          config.javascript_driver = :chrome
          config.default_max_wait_time = 10
          # https://github.com/mattheworiordan/capybara-screenshot/issues/164
          config.save_path = 'tmp'
        end
      end

      class Session
        include Capybara::DSL

        def initialize(instance, page = nil)
          @instance = instance
          @address = host + page&.path
        end

        def host
          if @instance.is_a?(Symbol)
            Runtime::Scenario.send("#{@instance}_address")
          else
            @instance.to_s
          end
        end

        def perform(&block)
          visit(@address)

          yield if block_given?
        rescue
          raise if block.nil?

          # RSpec examples will take care of screenshots on their own
          #
          unless block.binding.receiver.is_a?(RSpec::Core::ExampleGroup)
            screenshot_and_save_page
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
          reset_session!
        end
      end
    end
  end
end

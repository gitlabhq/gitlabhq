# frozen_string_literal: true

require 'rspec/core'
require 'rspec/expectations'
require 'capybara/rspec'
require 'capybara-screenshot/rspec'
require 'selenium-webdriver'

module QA
  module Runtime
    class Browser
      include QA::Scenario::Actable

      NotRespondingError = Class.new(RuntimeError)

      CAPYBARA_MAX_WAIT_TIME = 10

      def initialize
        self.class.configure!
      end

      def self.blank_page?
        ['', 'about:blank', 'data:,'].include?(Capybara.current_session.driver.browser.current_url)
      rescue
        true
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
      def visit(address, page_class, &block)
        Browser::Session.new(address, page_class).perform(&block)
      end

      def self.visit(address, page_class, &block)
        new.visit(address, page_class, &block)
      end

      def self.configure!
        RSpec.configure do |config|
          config.define_derived_metadata(file_path: %r{/qa/specs/features/}) do |metadata|
            metadata[:type] = :feature
          end
        end

        Capybara.server_port = 9887 + ENV['TEST_ENV_NUMBER'].to_i

        return if Capybara.drivers.include?(:chrome)

        Capybara.register_driver QA::Runtime::Env.browser do |app|
          capabilities = Selenium::WebDriver::Remote::Capabilities.send(QA::Runtime::Env.browser,
            # This enables access to logs with `page.driver.manage.get_log(:browser)`
            loggingPrefs: {
              browser: "ALL",
              client: "ALL",
              driver: "ALL",
              server: "ALL"
            })

          if QA::Runtime::Env.accept_insecure_certs?
            capabilities['acceptInsecureCerts'] = true
          end

          # QA::Runtime::Env.browser.capitalize will work for every driver type except PhantomJS.
          # We will have no use to use PhantomJS so this shouldn't be a problem.
          options = Selenium::WebDriver.const_get(QA::Runtime::Env.browser.capitalize, false)::Options.new

          if QA::Runtime::Env.browser == :chrome
            options.add_argument("window-size=1480,2200")

            # Chrome won't work properly in a Docker container in sandbox mode
            options.add_argument("no-sandbox")

            # Run headless by default unless CHROME_HEADLESS is false
            if QA::Runtime::Env.chrome_headless?
              options.add_argument("headless")

              # Chrome documentation says this flag is needed for now
              # https://developers.google.com/web/updates/2017/04/headless-chrome#cli
              options.add_argument("disable-gpu")
            end

            # Disable /dev/shm use in CI. See https://gitlab.com/gitlab-org/gitlab/issues/4252
            options.add_argument("disable-dev-shm-usage") if QA::Runtime::Env.running_in_ci?
          end

          # Use the same profile on QA runs if CHROME_REUSE_PROFILE is true.
          # Useful to speed up local QA.
          if QA::Runtime::Env.reuse_chrome_profile?
            qa_profile_dir = ::File.expand_path('../../tmp/qa-profile', __dir__)
            options.add_argument("user-data-dir=#{qa_profile_dir}")
          end

          selenium_options = {
            browser: QA::Runtime::Env.browser,
            clear_local_storage: true,
            desired_capabilities: capabilities,
            options: options
          }

          selenium_options[:url] = QA::Runtime::Env.remote_grid if QA::Runtime::Env.remote_grid

          Capybara::Selenium::Driver.new(
            app,
            selenium_options
          )
        end

        # Keep only the screenshots generated from the last failing test suite
        Capybara::Screenshot.prune_strategy = :keep_last_run

        # From https://github.com/mattheworiordan/capybara-screenshot/issues/84#issuecomment-41219326
        Capybara::Screenshot.register_driver(QA::Runtime::Env.browser) do |driver, path|
          driver.browser.save_screenshot(path)
        end

        Capybara::Screenshot.register_filename_prefix_formatter(:rspec) do |example|
          ::File.join(QA::Runtime::Namespace.name, example.file_path.sub('./qa/specs/features/', ''))
        end

        Capybara.configure do |config|
          config.default_driver = QA::Runtime::Env.browser
          config.javascript_driver = QA::Runtime::Env.browser
          config.default_max_wait_time = CAPYBARA_MAX_WAIT_TIME
          # https://github.com/mattheworiordan/capybara-screenshot/issues/164
          config.save_path = ::File.expand_path('../../tmp', __dir__)
        end
      end

      class Session
        include Capybara::DSL

        attr_reader :page_class

        def initialize(instance, page_class)
          @session_address = Runtime::Address.new(instance, page_class)
          @page_class = page_class
        end

        def url
          @session_address.address
        end

        def perform(&block)
          visit(url)

          page_class.validate_elements_present!

          if QA::Runtime::Env.qa_cookies
            browser = Capybara.current_session.driver.browser
            QA::Runtime::Env.qa_cookies.each do |cookie|
              name, value = cookie.split("=")
              value ||= ""
              browser.manage.add_cookie name: name, value: value
            end
          end

          yield.tap { clear! } if block_given?
        end

        ##
        # Selenium allows to reset session cookies for current domain only.
        #
        # See gitlab-org/gitlab-qa#102
        #
        def clear!
          visit(url)
          reset_session!
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'rspec/core'
require 'rspec/expectations'
require 'capybara/rspec'
require 'capybara-screenshot/rspec'
require 'webdrivers/chromedriver'
require 'webdrivers/geckodriver'

require 'gitlab_handbook'

module QA
  module Runtime
    class Browser
      include QA::Scenario::Actable

      NotRespondingError = Class.new(RuntimeError)

      CAPYBARA_MAX_WAIT_TIME = Env.max_capybara_wait_time

      def self.blank_page?
        ['', 'about:blank', 'data:,'].include?(Capybara.current_session.driver.browser.current_url)
      rescue StandardError
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

      # rubocop: disable Metrics/AbcSize
      def self.configure!
        return if @configured

        RSpec.configure do |config|
          config.define_derived_metadata(file_path: %r{/qa/specs/features/}) do |metadata|
            metadata[:type] = :feature
          end

          config.append_after(:each) do |example|
            if example.metadata[:screenshot]
              screenshot = example.metadata[:screenshot][:image] || example.metadata[:screenshot][:html]
              example.metadata[:stdout] = %([[ATTACHMENT|#{screenshot}]])
            end
          end
        end

        Capybara.server_port = 9887 + ENV['TEST_ENV_NUMBER'].to_i

        Capybara.register_driver QA::Runtime::Env.browser do |app|
          capabilities = Selenium::WebDriver::Remote::Capabilities.send(QA::Runtime::Env.browser)

          case QA::Runtime::Env.browser
          when :chrome
            capabilities['acceptInsecureCerts'] = true if QA::Runtime::Env.accept_insecure_certs?

            # set logging preferences
            # this enables access to logs with `page.driver.manage.get_log(:browser)`
            capabilities['goog:loggingPrefs'] = {
              browser: 'ALL',
              client: 'ALL',
              driver: 'ALL',
              server: 'ALL'
            }

            # Chrome won't work properly in a Docker container in sandbox mode
            capabilities['goog:chromeOptions'] = {
              args: %w[no-sandbox]
            }

            # Run headless by default unless WEBDRIVER_HEADLESS is false
            if QA::Runtime::Env.webdriver_headless?
              capabilities['goog:chromeOptions'][:args] << 'headless'

              # Chrome documentation says this flag is needed for now
              # https://developers.google.com/web/updates/2017/04/headless-chrome#cli
              capabilities['goog:chromeOptions'][:args] << 'disable-gpu'
            end

            # Disable /dev/shm use in CI. See https://gitlab.com/gitlab-org/gitlab/issues/4252
            capabilities['goog:chromeOptions'][:args] << 'disable-dev-shm-usage' if QA::Runtime::Env.disable_dev_shm?

            # Set chrome default download path

            capabilities['goog:chromeOptions'][:prefs] = {
              'download.default_directory' => File.expand_path(QA::Runtime::Env.chrome_default_download_path),
              'download.prompt_for_download' => false
            }

            # Specify the user-agent to allow challenges to be bypassed
            # See https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/11938
            if QA::Runtime::Env.user_agent
              capabilities['goog:chromeOptions'][:args] << "user-agent=#{QA::Runtime::Env.user_agent}"
            end

            if QA::Runtime::Env.remote_mobile_device_name
              capabilities['platformName'] = 'Android'
              capabilities['appium:automationName'] = 'UiAutomator2'
              capabilities['appium:deviceName'] = QA::Runtime::Env.remote_mobile_device_name
              capabilities['appium:platformVersion'] = 'latest'
            else
              capabilities['goog:chromeOptions'][:args] << 'window-size=1480,2200'
            end

          when :safari
            if QA::Runtime::Env.remote_mobile_device_name
              capabilities['platformName'] = 'iOS'
              capabilities['appium:automationName'] = 'XCUITest'
              capabilities['appium:deviceName'] = QA::Runtime::Env.remote_mobile_device_name
              capabilities['appium:platformVersion'] = 'latest'
            end

          when :firefox
            capabilities['acceptInsecureCerts'] = true if QA::Runtime::Env.accept_insecure_certs?
          end

          # Use the same profile on QA runs if CHROME_REUSE_PROFILE is true.
          # Useful to speed up local QA.
          if QA::Runtime::Env.reuse_chrome_profile?
            qa_profile_dir = ::File.expand_path('../../tmp/qa-profile', __dir__)
            capabilities['goog:chromeOptions'][:args] << "user-data-dir=#{qa_profile_dir}"
          end

          selenium_options = {
            browser: QA::Runtime::Env.browser,
            clear_local_storage: true,
            capabilities: capabilities
          }

          if QA::Runtime::Env.remote_grid
            selenium_options[:url] = QA::Runtime::Env.remote_grid
            capabilities[:browserVersion] = 'latest'
            capabilities['sauce:options'] = { tunnelIdentifier: QA::Runtime::Env.remote_tunnel_id }
          end

          Capybara::Selenium::Driver.new(
            app,
            **selenium_options
          )
        end

        # Keep only the screenshots generated from the last failing test suite
        Capybara::Screenshot.prune_strategy = :keep_last_run

        # From https://github.com/mattheworiordan/capybara-screenshot/issues/84#issuecomment-41219326
        Capybara::Screenshot.register_driver(QA::Runtime::Env.browser) do |driver, path|
          QA::Runtime::Logger.info("Saving screenshot..")
          driver.browser.save_screenshot(path)
        end

        Capybara::Screenshot.register_filename_prefix_formatter(:rspec) do |example|
          ::File.join(
            QA::Runtime::Namespace.name(reset_cache: false),
            example.full_description.downcase.parameterize(separator: "_")[0..79]
          )
        end

        Capybara.configure do |config|
          config.default_driver = QA::Runtime::Env.browser
          config.javascript_driver = QA::Runtime::Env.browser
          config.default_max_wait_time = CAPYBARA_MAX_WAIT_TIME
          # https://github.com/mattheworiordan/capybara-screenshot/issues/164
          config.save_path = ::File.expand_path('../../tmp', __dir__)

          # Cabybara 3 does not normalize text by default, so older tests
          # fail because of unexpected line breaks and other white space
          config.default_normalize_ws = true
        end

        Chemlab.configure do |config|
          config.browser = Capybara.current_session.driver.browser # reuse Capybara session
          config.libraries = [GitlabHandbook]
          config.base_url = Runtime::Scenario.attributes[:gitlab_address] # reuse GitLab address
          config.hide_banner = true
        end

        @configured = true
      end
      # rubocop: enable Metrics/AbcSize

      class Session
        include Capybara::DSL

        attr_reader :page_class

        def initialize(instance, page_class)
          @session_address = Runtime::Address.new(instance, page_class)
          @page_class = page_class

          Session.enable_interception if Runtime::Env.can_intercept?
        end

        def url
          @session_address.address
        end

        def perform(&block)
          visit(url)

          simulate_slow_connection if Runtime::Env.simulate_slow_connection?

          # Wait until the new page is ready for us to interact with it
          Support::WaitForRequests.wait_for_requests

          page_class.validate_elements_present! if page_class.respond_to?(:validate_elements_present!)

          if QA::Runtime::Env.qa_cookies
            browser = Capybara.current_session.driver.browser
            QA::Runtime::Env.qa_cookies.each do |cookie|
              name, value = cookie.split("=")
              value ||= ""
              browser.manage.add_cookie name: name, value: value
            end
          end

          yield.tap { clear! } if block
        end

        # To redirect the browser to a canary or non-canary web node
        #   after loading a subject test page
        # @param [Boolean] Send to canary true or false
        # @example:
        #   Runtime::Browser::Session.target_canary(true)
        def self.target_canary(enable_canary)
          if QA::Runtime::Env.qa_cookies.to_s.include?("gitlab_canary=true")
            QA::Runtime::Logger.warn("WARNING: Setting cookie through QA_COOKIES var is incompatible with this method.")
            return
          end

          browser = Capybara.current_session.driver.browser

          if enable_canary
            browser.manage.add_cookie name: "gitlab_canary", value: "true"
          else
            browser.manage.delete_cookie("gitlab_canary")
          end

          browser.navigate.refresh
        end

        ##
        # Selenium allows to reset session cookies for current domain only.
        #
        # See gitlab-org/gitlab-qa#102
        #
        def clear!
          visit(url)
          reset_session!
          @network_conditions_configured = false
        end

        def self.enable_interception
          script = File.read("#{__dir__}/script_extensions/interceptor.js")
          command = {
            cmd: 'Page.addScriptToEvaluateOnNewDocument',
            params: {
              source: script
            }
          }
          @interceptor_script_params = Capybara.current_session.driver.browser.send(:bridge).send_command(command)
        end

        def self.disable_interception
          return unless @interceptor_script_params

          command = {
            cmd: 'Page.removeScriptToEvaluateOnNewDocument',
            params: @interceptor_script_params
          }
          Capybara.current_session.driver.browser.send(:bridge).send_command(command)
        end

        private

        def simulate_slow_connection
          return if @network_conditions_configured

          QA::Runtime::Logger.info(
            <<~MSG.tr("\n", " ")
              Simulating a slow connection with additional latency
              of #{Runtime::Env.slow_connection_latency} ms and a maximum
              throughput of #{Runtime::Env.slow_connection_throughput} kbps
            MSG
          )

          Capybara.current_session.driver.browser.network_conditions = {
            latency: Runtime::Env.slow_connection_latency,
            throughput: Runtime::Env.slow_connection_throughput * 1000
          }

          @network_conditions_configured = true
        end
      end
    end
  end
end

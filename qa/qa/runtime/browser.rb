# frozen_string_literal: true

require 'rspec/core'
require 'rspec/expectations'
require 'capybara/rspec'
require 'capybara-screenshot/rspec'

module QA
  module Runtime
    class Browser
      include QA::Scenario::Actable

      NotRespondingError = Class.new(RuntimeError)

      CAPYBARA_MAX_WAIT_TIME = Env.max_capybara_wait_time
      DEFAULT_WINDOW_SIZE = '1480,2200'

      def self.blank_page?
        ['', 'about:blank', 'data:,'].include?(Capybara.current_session.driver.browser.current_url)
      rescue StandardError
        true
      end

      def self.visit(address, page_class, &)
        new.visit(address, page_class, &)
      end

      def self.configure! # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity -- TODO: Break up this method
        return if QA::Runtime::Env.dry_run
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
          webdriver_options = Selenium::WebDriver::Options.send(QA::Runtime::Env.browser)

          case QA::Runtime::Env.browser
          when :chrome
            # Chrome won't work properly in a Docker container in sandbox mode
            chrome_options = { args: %w[no-sandbox] }

            # Run headless by default unless WEBDRIVER_HEADLESS is false
            chrome_options[:args] << 'headless=new' if QA::Runtime::Env.webdriver_headless?

            # Disable /dev/shm use in CI. See https://gitlab.com/gitlab-org/gitlab/issues/4252
            chrome_options[:args] << 'disable-dev-shm-usage' if QA::Runtime::Env.disable_dev_shm?

            chrome_options[:args] << 'disable-search-engine-choice-screen'

            # Allows chrome to consider all actions as secure when no ssl is used
            Runtime::Scenario.attributes[:gitlab_address].tap do |address|
              next unless address.start_with?('http://')

              chrome_options[:args] << "unsafely-treat-insecure-origin-as-secure=#{address}"
            end

            # Set chrome default download path
            # TODO: Set for remote grid as well once Sauce Labs tests are deprecated and Options.chrome is added
            # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/112258
            unless QA::Runtime::Env.remote_grid
              chrome_options[:prefs] = {
                'download.default_directory' => File.expand_path(QA::Runtime::Env.chrome_default_download_path),
                'download.prompt_for_download' => false
              }
            end

            # Specify the user-agent to allow challenges to be bypassed
            # See https://gitlab.com/gitlab-com/gl-infra/infrastructure/-/issues/11938
            unless QA::Runtime::Env.user_agent.blank?
              chrome_options[:args] << "user-agent=#{QA::Runtime::Env.user_agent}"
            end

            if QA::Runtime::Env.remote_mobile_device_name
              webdriver_options.platform_name = 'Android'
              webdriver_options.add_option('appium:automationName', 'UiAutomator2')
              webdriver_options.add_option('appium:deviceName', QA::Runtime::Env.remote_mobile_device_name)
              webdriver_options.add_option('appium:platformVersion', 'latest')
            else
              chrome_options[:args] << "window-size=#{DEFAULT_WINDOW_SIZE}"
            end

            # Slack tries to open an external URL handler
            # The test needs to default the handler to always open Slack
            # to prevent a blocking popup.
            if QA::Runtime::Env.slack_workspace
              slack_default_preference = {
                'protocol_handler' => {
                  'allowed_origin_protocol_pairs' => {
                    "https://#{QA::Runtime::Env.slack_workspace}.slack.com" => {
                      'slack' => true
                    }
                  }
                }
              }

              default_profile = File.join("#{chrome_profile_location}/Default")
              FileUtils.mkdir_p(default_profile)
              preferences = slack_default_preference

              # mutate the preferences if it exists
              # else write a new file
              if File.exist?("#{default_profile}/Preferences")
                begin
                  preferences = JSON.parse(File.read("#{default_profile}/Preferences"))
                  preferences.deep_merge!(slack_default_preference)
                rescue JSON::ParserError => _
                end
              end

              File.write("#{default_profile}/Preferences", preferences.to_json)
              append_chrome_profile_to_capabilities(chrome_options)
            end

            # Use the same profile on QA runs if CHROME_REUSE_PROFILE is true.
            # Useful to speed up local QA.
            append_chrome_profile_to_capabilities(chrome_options) if QA::Runtime::Env.reuse_chrome_profile?

            webdriver_options.args = chrome_options[:args]
            webdriver_options.prefs = chrome_options[:prefs]
            webdriver_options.accept_insecure_certs = true if QA::Runtime::Env.accept_insecure_certs?
            # set logging preferences
            # this enables access to logs with `page.driver.manage.get_log(:browser)`
            webdriver_options.logging_prefs = {
              browser: 'ALL',
              client: 'ALL',
              driver: 'ALL',
              server: 'ALL'
            }

          when :safari
            if QA::Runtime::Env.remote_mobile_device_name
              webdriver_options.platform_name = 'iOS'
              webdriver_options.add_option('appium:automationName', 'XCUITest')
              webdriver_options.add_option('appium:deviceName', QA::Runtime::Env.remote_mobile_device_name)
              webdriver_options.add_option('appium:platformVersion', 'latest')
            end
          when :firefox
            webdriver_options.accept_insecure_certs = true if QA::Runtime::Env.accept_insecure_certs?
            webdriver_options.args << "--headless" if QA::Runtime::Env.webdriver_headless?
          when :edge
            webdriver_options.args << "--window-size=#{DEFAULT_WINDOW_SIZE}"
            webdriver_options.args << "headless" if QA::Runtime::Env.webdriver_headless?
          end

          selenium_options = {
            browser: QA::Runtime::Env.browser,
            clear_local_storage: true
          }

          if QA::Runtime::Env.remote_grid
            selenium_options[:browser] = :remote
            selenium_options[:url] = QA::Runtime::Env.remote_grid
            webdriver_options.browser_version = QA::Runtime::Env.selenoid_browser_version
          end

          if QA::Runtime::Env.remote_tunnel_id
            webdriver_options.add_option('sauce:options', {
              tunnelIdentifier: QA::Runtime::Env.remote_tunnel_id
            })
          end

          if QA::Runtime::Env.record_video?
            webdriver_options.add_option('selenoid:options', {
              enableVideo: true
            })
          end

          Capybara::Selenium::Driver.new(app, options: webdriver_options, **selenium_options)
        end

        # Keep only the screenshots generated from the last failing test suite
        Capybara::Screenshot.prune_strategy = :keep_last_run

        # From https://github.com/mattheworiordan/capybara-screenshot/issues/84#issuecomment-41219326
        Capybara::Screenshot.register_driver(QA::Runtime::Env.browser) do |driver, path|
          QA::Runtime::Logger.info("Saving screenshot..")
          driver.browser.save_screenshot(path)
        end

        Capybara::Screenshot.register_filename_prefix_formatter(:rspec) do |example|
          ::File.join("failure_screenshots", example.full_description.downcase.parameterize(separator: "_")[0..79])
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

        @configured = true
      end

      def self.append_chrome_profile_to_capabilities(chrome_options)
        return if chrome_options[:args].include?(chrome_profile_location)

        chrome_options[:args] << "user-data-dir=#{chrome_profile_location}"
      end

      def self.chrome_profile_location
        ::File.expand_path('../../tmp/qa-profile', __dir__)
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
      def visit(address, page_class, &)
        Browser::Session.new(address, page_class).perform(&)
      end

      class Session
        include Capybara::DSL

        attr_reader :page_class

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

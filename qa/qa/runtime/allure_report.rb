# frozen_string_literal: true

require 'active_support/core_ext/enumerable'

module QA
  module Runtime
    class AllureReport
      extend QA::Support::API

      class << self
        # Configure allure reports
        #
        # @return [void]
        def configure!
          return if Env.dry_run
          return unless Env.generate_allure_report?

          configure_allure
          configure_attachments
          configure_rspec
        end

        private

        # Configure allure reporter
        #
        # @return [void]
        def configure_allure
          AllureRspec.configure do |config|
            config.results_directory = ENV['QA_ALLURE_RESULTS_DIRECTORY'] || 'tmp/allure-results'
            config.clean_results_directory = false

            # automatically attach links to testcases and issues
            config.tms_tag = :testcase
            config.link_tms_pattern = '{}'
            config.issue_tag = :issue
            config.link_issue_pattern = '{}'

            # custom grouping of failures, https://docs.qameta.io/allure-report/#_categories_2
            config.categories = File.new(File.join(Runtime::Path.qa_root, "allure", "categories.json"))

            if Env.running_in_ci?
              config.environment_properties = environment_info
              # Set custom environment name to separate same specs executed in different jobs
              # Drop number postfixes from parallel jobs by only matching non whitespace characters
              config.environment = Env.ci_job_name.match(/^\S+/)[0]
            end
          end
        end

        # Set up failure screenshot attachments
        #
        # @return [void]
        def configure_attachments
          Capybara::Screenshot.after_save_screenshot do |path|
            Allure.add_attachment(
              name: 'screenshot',
              source: File.open(path),
              type: Allure::ContentType::PNG,
              test_case: true
            )
          end
          Capybara::Screenshot.after_save_html do |path|
            Allure.add_attachment(
              name: 'html',
              source: File.open(path),
              type: 'text/html',
              test_case: true
            )
          end
        end

        # Configure rspec
        #
        # @return [void]
        def configure_rspec
          RSpec.configure do |config|
            config.add_formatter(QA::Support::Formatters::AllureMetadataFormatter)
            config.add_formatter(AllureRspecFormatter)

            config.append_after do
              Allure.add_attachment(
                name: 'browser.log',
                source: Capybara.current_session.driver.browser.logs.get(:browser).map(&:to_s).join("\n\n"),
                type: Allure::ContentType::TXT,
                test_case: true
              )
            end
          end
        end

        # Gitlab version and revision information
        #
        # @return [Hash]
        def environment_info
          -> do
            api_token = User::Data.admin_api_token || User::Data.test_user_api_token
            return {} unless api_token

            response = get(API::Request.new(API::Client.new(personal_access_token: api_token), '/metadata').url)
            JSON.parse(response.body, symbolize_names: true).then do |metadata|
              {
                **metadata.slice(:version, :revision),
                kas_version: metadata.dig(:kas, :version)
              }.compact
            end
          rescue StandardError, ArgumentError => e
            Logger.error("Failed to attach version info to allure report: #{e}")
            {}
          end
        end
      end
    end
  end
end

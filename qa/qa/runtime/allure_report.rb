# frozen_string_literal: true

require 'active_support/core_ext/enumerable'

module QA
  module Runtime
    class AllureReport
      class << self
        # Configure allure reports
        #
        # @return [void]
        def configure!
          return unless Env.generate_allure_report?

          require 'allure-rspec'

          configure_allure
          configure_attachments
          configure_rspec
        end

        private

        # Configure allure reporter
        #
        # @return [void]
        def configure_allure
          # Match job names like ee:relative, ce:update etc. and set as execution environment
          env_matcher = /^(?<env>\w{2}:\S+)/

          AllureRspec.configure do |config|
            config.results_directory = 'tmp/allure-results'
            config.clean_results_directory = true
            config.environment_properties = environment_info if Env.running_in_ci?

            # Set custom environment name to separate same specs executed on different environments
            if Env.running_in_ci? && Env.ci_job_name.match?(env_matcher)
              config.environment = Env.ci_job_name.match(env_matcher).named_captures['env']
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
            config.add_formatter(AllureRspecFormatter)
            config.add_formatter(QA::Support::AllureMetadataFormatter)
          end
        end

        # Custom environment info hash
        #
        # @return [Hash]
        def environment_info
          %w[
            CI_COMMIT_SHA
            CI_MERGE_REQUEST_SOURCE_BRANCH_SHA
            CI_MERGE_REQUEST_IID
            TOP_UPSTREAM_SOURCE_SHA
            TOP_UPSTREAM_MERGE_REQUEST_IID
            DEPLOY_VERSION
            GITLAB_VERSION
            GITLAB_SHELL_VERSION
            GITLAB_ELASTICSEARCH_INDEXER_VERSION
            GITLAB_KAS_VERSION
            GITLAB_WORKHORSE_VERSION
            GITLAB_PAGES_VERSION
            GITALY_SERVER_VERSION
            QA_IMAGE
            QA_BROWSER
          ].index_with { |val| ENV[val] }.compact_blank
        end
      end
    end
  end
end

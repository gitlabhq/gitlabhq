# frozen_string_literal: true

require 'json'

module QA
  module Support
    module Formatters
      # RSpec formatter to map E2E specs to diff files
      class CoverbandFormatter < ::RSpec::Core::Formatters::BaseFormatter
        include Support::API

        def initialize(output)
          super

          @full_coverage_by_example = {}
          @logger = Runtime::Logger.logger
          @cov_api_endpoint = "#{Runtime::Scenario.gitlab_address}/api/v4/internal/coverage"
          @headers_access_token = {
            "PRIVATE-TOKEN" => Runtime::User::Data.admin_api_token || Runtime::User::Data::DEFAULT_ADMIN_API_TOKEN
          }
        end

        ::RSpec::Core::Formatters.register(
          self,
          :example_started,
          :example_finished,
          :stop
        )

        # Runs at the end of suite
        #
        # @param [RSpec::Core::Notifications::ExamplesNotification] notification
        # @return [void]
        def stop(_notification)
          save_coverage_data
        end

        # Example start event
        def example_started(example_notification)
          return if example_notification.example.metadata[:skip]

          response = nil
          QA::Support::Retrier.retry_until(max_attempts: 5, sleep_interval: 1) do
            response = delete(cov_api_endpoint, headers: headers_access_token)
            next true if response.code == 200

            logger.debug("Failed to clear coverage, code: #{response.code}, body: #{response.body}")
            false
          end
          logger.info("Cleared coverage data")
        rescue StandardError
          logger.error("Failed to clear coverage, code: #{response.code}, body: #{response.body}")
        end

        # Example finish event
        def example_finished(example_notification)
          return if example_notification.example.metadata[:skip] || example_failed?(example_notification)

          response = nil
          QA::Support::Retrier.retry_until(max_attempts: 1, sleep_interval: 2) do
            response = get(cov_api_endpoint, headers: headers_access_token)
            coverage = JSON.parse(response.body)
            next true if response.code == 200 && coverage.any?

            if response.code != 200
              logger.debug("Fetching coverage data failed, code: #{response.code}, body: #{response.body}")
            end

            logger.debug("Fetching coverage data failed, no coverage data available") if coverage.empty?
            false
          end

          example_path = example_notification.example.metadata[:location]
          full_coverage_data = JSON.parse(response.body)

          # Store full coverage data for both test selection and LCOV conversion
          full_coverage_by_example[example_path] = full_coverage_data

          logger.info("Fetched coverage data")
        rescue StandardError
          logger.error("Failed to fetch coverage data, code: #{response.code}, body: #{response.body}")
        end

        def example_failed?(example_notification)
          example_notification.example.execution_result.status == :failed
        end

        # Save coverage data
        # - Test mapping (file paths only) for test selection
        # - Full coverage data for LCOV conversion
        #
        # @return [void]
        def save_coverage_data
          return if full_coverage_by_example.empty?

          # Derive test mapping from full coverage data
          test_mapping = full_coverage_by_example.transform_values(&:keys)

          mapping_file = "tmp/test-code-paths-mapping-#{ENV['CI_JOB_NAME_SLUG'] || 'local'}-#{SecureRandom.hex(6)}.json"
          File.write(mapping_file, test_mapping.to_json)
          logger.info("Saved test coverage mapping data to #{mapping_file}")

          coverage_file = "tmp/coverband-coverage-#{ENV['CI_JOB_NAME_SLUG'] || 'local'}-#{SecureRandom.hex(6)}.json"
          File.write(coverage_file, full_coverage_by_example.to_json)
          logger.info("Saved full Coverband coverage data to #{coverage_file}")
        rescue StandardError => e
          logger.error("Failed to save coverage data, error: #{e}")
        end

        private

        attr_reader :full_coverage_by_example, :logger, :headers_access_token, :cov_api_endpoint
      end
    end
  end
end

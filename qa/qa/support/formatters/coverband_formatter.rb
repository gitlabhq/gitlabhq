# frozen_string_literal: true

require 'json'

module QA
  module Support
    module Formatters
      # RSpec formatter to map E2E specs to diff files
      class CoverbandFormatter < ::RSpec::Core::Formatters::BaseFormatter
        include Support::API

        COVERAGE_API_PATH = '/api/v4/internal/coverage'

        def initialize(output)
          super
          @test_mapping = Hash.new { |hsh, key| hsh[key] = [] }
          @logger = Runtime::Logger.logger
          @headers_access_token = { "PRIVATE-TOKEN" => Runtime::Env.admin_personal_access_token }
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
          logger.info("Saving test coverage mapping json file")

          save_test_mapping
        end

        # Example start event
        def example_started(_example_notification)
          QA::Support::Retrier.retry_until(max_attempts: 5, sleep_interval: 1, message: "Retry clear coverage") do
            resp = delete("#{Runtime::Scenario.gitlab_address}#{COVERAGE_API_PATH}",
              headers: headers_access_token)

            logger.error("Failed to clear coverage, code: #{resp.code}, body: #{resp.body}") if resp.code != 200

            resp.code == 200
          end
          logger.debug("Cleared coverage data before example starts")
        rescue StandardError => e
          logger.error("Failed to clear coverage. Exception trace: #{e}")
        end

        # Example finish event
        def example_finished(example_notification)
          cov_resp = nil
          QA::Support::Retrier.retry_until(max_attempts: 10, sleep_interval: 2, message: "Retry fetch coverage") do
            cov_resp = get("#{Runtime::Scenario.gitlab_address}/api/v4/internal/coverage",
              headers: headers_access_token)

            if cov_resp.code != 200
              logger.error("Fetching coverage data failed, code: #{cov_resp.code}, body: #{cov_resp.body}")
            end

            cov_resp.code == 200 && !JSON.parse(cov_resp.body).empty?
          end

          example_path = example_notification.example.metadata[:location]
          test_mapping[example_path] = JSON.parse(cov_resp.body) unless example_failed?(example_notification)
          logger.debug("Coverage paths were stored in mapping hash")
        rescue StandardError => e
          logger.error("Failed to fetch coverage mapping. Trace: #{e}")
        end

        def example_failed?(example_notification)
          example_notification.example.execution_result.status == :failed
        end

        # Save coverage test mapping file
        #
        # @return [void]
        def save_test_mapping
          file = "tmp/test-code-paths-mapping-#{ENV['CI_JOB_NAME_SLUG'] || 'local'}-#{SecureRandom.hex(6)}.json"
          # To write two different files in case of failed specs being retried

          File.write(file, test_mapping.to_json)
          logger.debug("Saved test code paths mapping to #{file}")
        rescue StandardError => e
          logger.error("Failed to save test code paths mapping, error: #{e}")
        end

        private

        attr_reader :test_mapping, :logger, :headers_access_token
      end
    end
  end
end

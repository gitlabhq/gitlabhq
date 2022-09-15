# frozen_string_literal: true

module QA
  module Tools
    module Ci
      class TestResults
        include Helpers

        def initialize(pipeline_name, test_report_job_name, report_path)
          @pipeline_name = pipeline_name
          @test_report_job_name = test_report_job_name
          @report_path = report_path
        end

        # Get test report artifacts from downstream pipeline
        #
        # @param [String] pipeline_name
        # @param [String] test_report_job_name
        # @param [String] report_path
        # @return [void]
        def self.get(pipeline_name, test_report_job_name, report_path)
          new(pipeline_name, test_report_job_name, report_path).download_test_results
        end

        # Download test results from child pipeline
        #
        # @return [void]
        def download_test_results
          logger.info("Fetching test results for '#{pipeline_name}'")

          logger.debug("  fetching pipeline id of '#{pipeline_name}' child pipeline")
          downstream_pipeline_id = api_get("#{pipelines_url(pipeline_id)}/bridges")
            .find { |bridge| bridge[:name] == pipeline_name }
            &.dig(:downstream_pipeline, :id)
          return logger.error("Child pipeline '#{pipeline_name}' not found!") unless downstream_pipeline_id

          logger.debug("  fetching job id of test report job")
          job_id = api_get("#{pipelines_url(downstream_pipeline_id)}/jobs")
            .find { |job| job[:name] == test_report_job_name }
            &.fetch(:id)
          return logger.error("Test report job '#{test_report_job_name}' not found!") unless job_id

          logger.debug("  fetching test results artifact archive")
          response = api_get("/projects/#{project_id}/jobs/#{job_id}/artifacts", raw_response: true)

          logger.info("Extracting test result archive")
          system("unzip", "-o", "-d", report_path, response.file.path)
        end

        private

        attr_reader :pipeline_name, :test_report_job_name, :report_path

        # Base get pipeline url
        #
        # @param [Integer] id
        # @return [String]
        def pipelines_url(id)
          "/projects/#{project_id}/pipelines/#{id}"
        end

        # Current pipeline id
        #
        # @return [String]
        def pipeline_id
          ENV["CI_PIPELINE_ID"]
        end

        # Current project id
        #
        # @return [String]
        def project_id
          ENV["CI_PROJECT_ID"]
        end
      end
    end
  end
end

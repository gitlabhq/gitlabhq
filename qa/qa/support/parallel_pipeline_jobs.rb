# frozen_string_literal: true

module QA
  module Support
    # Helper utility to fetch parallel job names in a given pipelines stage
    #
    class ParallelPipelineJobs
      include API

      PARALLEL_JOB_NAME_PATTERN = %r{^\S+ \d+/\d+$}

      def initialize(stage_name:, project_id:, pipeline_id:, access_token:)
        @stage_name = stage_name
        @access_token = access_token
        @project_id = project_id || raise("project_id must be provided")
        @pipeline_id = pipeline_id || raise("pipeline_id must be provided")
      end

      # Fetch parallel job names in given stage
      #
      # Default to arguments available on CI
      #
      # @param [String] stage_name
      # @param [Integer] project_id
      # @param [Integer] pipeline_id
      # @param [String] access_token
      # @return [Array]
      def self.fetch(
        stage_name:,
        access_token:,
        project_id: ENV["CI_PROJECT_ID"],
        pipeline_id: ENV["CI_PIPELINE_ID"]
      )
        new(
          stage_name: stage_name,
          project_id: project_id,
          pipeline_id: pipeline_id,
          access_token: access_token
        ).parallel_jobs
      end

      # Parallel job list
      #
      # @return [Array<String>]
      def parallel_jobs
        api_get("projects/#{project_id}/pipelines/#{pipeline_id}/jobs?per_page=100")
          .select { |job| job[:stage] == stage_name && job[:name].match?(PARALLEL_JOB_NAME_PATTERN) }
          .map { |job| job[:name].gsub(%r{ \d+/\d+}, "") }
          .uniq
      end

      private

      attr_reader :stage_name, :access_token, :project_id, :pipeline_id

      # Api get request
      #
      # @param [String] path
      # @param [Hash] payload
      # @return [Hash, Array]
      def api_get(path)
        response = get("#{api_url}/#{path}", { headers: { "PRIVATE-TOKEN" => access_token } })
        raise "Failed to fetch pipeline jobs: '#{response.body}'" unless response.code == API::HTTP_STATUS_OK

        parse_body(response)
      end

      # Gitlab api url
      #
      # @return [String]
      def api_url
        @api_url ||= ENV['CI_API_V4_URL'] || "https://gitlab.com/api/v4"
      end
    end
  end
end

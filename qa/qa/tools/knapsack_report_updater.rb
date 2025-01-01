# frozen_string_literal: true

module QA
  module Tools
    class KnapsackReportUpdater
      include Support::API
      include Ci::Helpers

      GITLAB_PROJECT_ID = 278964
      UPDATE_BRANCH_NAME = "qa-knapsack-master-report-update"

      def self.run
        new.update_master_report
      end

      # Create master_report.json merge request
      #
      # @return [void]
      def update_master_report
        create_branch
        create_commit
        create_mr
      end

      private

      # Knapsack report generator
      #
      # @return [QA::Support::KnapsackReport]
      def knapsack_reporter
        @knapsack_reporter = Support::KnapsackReport.new(logger)
      end

      # Gitlab access token
      #
      # @return [String]
      def gitlab_access_token
        @gitlab_access_token ||= ENV["GITLAB_ACCESS_TOKEN"] || raise("Missing GITLAB_ACCESS_TOKEN env variable")
      end

      # Gitlab api url
      #
      # @return [String]
      def gitlab_api_url
        @gitlab_api_url ||= ENV["CI_API_V4_URL"] || raise("Missing CI_API_V4_URL env variable")
      end

      # Api request headers
      #
      # @return [Hash]
      def api_headers
        @api_headers ||= {
          headers: { "PRIVATE-TOKEN" => gitlab_access_token }
        }
      end

      # Create branch for knapsack report update
      #
      # @return [void]
      def create_branch
        logger.info("Creating branch '#{UPDATE_BRANCH_NAME}' branch")
        api_request(:post, "repository/branches", {
          branch: UPDATE_BRANCH_NAME,
          ref: "master"
        })
      rescue StandardError => e
        raise e unless e.message.include?("Branch already exists")

        logger.warn("Branch '#{UPDATE_BRANCH_NAME}' already exists, recreating it.")
        api_request(:delete, "repository/branches/#{UPDATE_BRANCH_NAME}")
        retry
      end

      # Create update commit for knapsack report
      #
      # @return [void]
      def create_commit
        logger.info("Creating master_report.json update commit")
        runtime_report = knapsack_reporter.create_merged_runtime_report.sort.to_h

        api_request(:post, "repository/commits", {
          branch: UPDATE_BRANCH_NAME,
          commit_message: "Update master_report.json for E2E tests",
          actions: [
            {
              action: "update",
              file_path: File.join("qa", Support::KnapsackReport::RUNTIME_REPORT),
              content: "#{JSON.pretty_generate(runtime_report)}\n"
            },
            {
              action: "update",
              file_path: File.join("qa", Support::KnapsackReport::FALLBACK_REPORT),
              content: "#{JSON.pretty_generate(knapsack_reporter.create_knapsack_report(runtime_report).sort.to_h)}\n"
            }
          ]
        })
      end

      # Create merge request with updated knapsack master report
      #
      # @return [void]
      def create_mr
        logger.info("Creating merge request")
        resp = api_request(:post, "merge_requests", {
          source_branch: UPDATE_BRANCH_NAME,
          target_branch: "master",
          title: "Update master_report.json for E2E tests",
          remove_source_branch: true,
          squash: true,
          labels: "Quality,team::Test and Tools Infrastructure,type::maintenance,maintenance::pipelines",
          description: <<~DESCRIPTION
            Update fallback knapsack report with latest spec runtime data.

            @gl-dx/qe-maintainers please review and merge.
          DESCRIPTION
        })

        logger.info("Merge request created: #{resp[:web_url]}")
      end

      # Api update request
      #
      # @param [String] verb
      # @param [String] path
      # @param [Hash] payload
      # @return [Hash, Array]
      def api_request(verb, path, payload = nil)
        args = [verb, "#{gitlab_api_url}/projects/#{GITLAB_PROJECT_ID}/#{path}", payload, api_headers].compact
        response = public_send(*args)
        raise "Api request to #{path} failed! Body: #{response.body}" unless success?(response.code)
        return {} if response.body.empty?

        parse_body(response)
      end
    end
  end
end

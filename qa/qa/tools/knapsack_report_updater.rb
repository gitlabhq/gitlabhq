# frozen_string_literal: true

module QA
  module Tools
    class KnapsackReportUpdater
      include Support::API
      include Ci::Helpers

      GITLAB_PROJECT_ID = 278964
      UPDATE_BRANCH_NAME = "qa-knapsack-master-report-update"

      DEFAULT_WAIT_BEFORE_APPROVE = 30
      DEFAULT_WAIT_BEFORE_MERGE = 120

      def self.run(wait_before_approve: DEFAULT_WAIT_BEFORE_APPROVE, wait_before_merge: DEFAULT_WAIT_BEFORE_MERGE)
        new(wait_before_approve: wait_before_approve, wait_before_merge: wait_before_merge).update_master_report
      end

      def initialize(wait_before_approve: DEFAULT_WAIT_BEFORE_APPROVE, wait_before_merge: DEFAULT_WAIT_BEFORE_MERGE)
        @wait_before_merge = wait_before_merge
        @wait_before_approve = wait_before_approve
      end

      # Create master_report.json merge request
      #
      # @return [void]
      def update_master_report
        create_branch
        create_commit
        create_mr
        return unless auto_merge?

        logger.info("Performing auto merge")
        approve_mr
        add_mr_to_merge_train
      end

      private

      attr_reader :wait_before_approve, :wait_before_merge, :mr_iid

      # Knapsack report generator
      #
      # @return [QA::Support::KnapsackReport]
      def knapsack_reporter
        @knapsack_reporter = Support::KnapsackReport.new(logger: logger)
      end

      # Gitlab api url
      #
      # @return [String]
      def gitlab_api_url
        @gitlab_api_url ||= ENV["CI_API_V4_URL"] || raise("Missing CI_API_V4_URL env variable")
      end

      # Gitlab access token
      #
      # @return [String]
      def gitlab_access_token
        @gitlab_access_token ||= ENV["GITLAB_ACCESS_TOKEN"] || raise("Missing GITLAB_ACCESS_TOKEN env variable")
      end

      # Knapsack report approver token
      #
      # @return [String]
      def approver_access_token
        @approver_access_token ||= ENV["QA_KNAPSACK_REPORT_APPROVER_TOKEN"].tap do |token|
          logger.warn("QA_KNAPSACK_REPORT_APPROVER_TOKEN is not set") unless token
        end
      end

      # Update mr approver user id
      #
      # @return [Integer]
      def approver_user_id
        @approver_user_id ||= approver_access_token.then do |token|
          next 0 unless token

          resp = get("#{gitlab_api_url}/user", token_header(token))
          next parse_body(resp)[:id] if success?(resp.code)

          logger.error("Failed to fetch approver user id! Response: #{resp.body}")
          0
        end
      end

      # Valid approver user is set
      #
      # @return [Boolean]
      def approver_user_valid?
        approver_user_id != 0
      end

      # Api request private token header
      #
      # @return [Hash]
      def token_header(token = gitlab_access_token)
        { headers: { "PRIVATE-TOKEN" => token } }
      end

      # Create branch for knapsack report update
      #
      # @return [void]
      def create_branch
        logger.info("Creating branch '#{UPDATE_BRANCH_NAME}' branch")
        retry_attempts = 0

        begin
          api_request(:post, "repository/branches", {
            branch: UPDATE_BRANCH_NAME,
            ref: "master"
          })
        rescue StandardError => e
          raise e if retry_attempts > 2

          if e.message.include?("Branch already exists")
            logger.warn("Branch '#{UPDATE_BRANCH_NAME}' already exists, recreating it.")
            api_request(:delete, "repository/branches/#{UPDATE_BRANCH_NAME}")
          end

          retry_attempts += 1
          retry
        end
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
          title: "Update knapsack runtime data for E2E tests",
          remove_source_branch: true,
          squash: true,
          reviewer_ids: approver_user_valid? ? [approver_user_id] : nil,
          labels: "group::development analytics,type::maintenance,maintenance::pipelines",
          description: "Update fallback knapsack report and example runtime data report.".then do |description|
            next description if approver_user_valid?

            "#{description}\n\ncc: @gl-dx/qe-maintainers"
          end
        }.compact)
        @mr_iid = resp[:iid]

        logger.info("Merge request created: #{resp[:web_url]}")
      end

      # Approve created merge request
      #
      # @return [void]
      def approve_mr
        logger.info("  approving merge request")
        # due to async nature of mr creation, approval is being reset because it happens before commit creation
        sleep(wait_before_approve)
        api_request(:post, "merge_requests/#{mr_iid}/approve", {}, token_header(approver_access_token))
      end

      # Add merge request to merge train
      #
      # @return [void]
      def add_mr_to_merge_train
        logger.info("  adding merge request to merge train")
        sleep(wait_before_merge) # gitlab-org/gitlab takes a long time to create pipeline after approval
        retry_attempts = 0
        approver_header = token_header(approver_access_token)

        begin
          api_request(:post, "merge_trains/merge_requests/#{mr_iid}", { when_pipeline_succeeds: true }, approver_header)
        rescue StandardError => e
          raise e if retry_attempts > 2

          logger.warn("  failed to add merge request to merge train, retrying...")
          logger.warn(e.message)
          retry_attempts += 1
          sleep(10)
          retry
        end
      end

      # Attempt to automatically merge created mr
      #
      # @return [Boolean]
      def auto_merge?
        (mr_iid && approver_user_valid?).tap do |auto_merge|
          logger.warn("Auto merge will not be performed!") unless auto_merge
        end
      end

      # Api update request
      #
      # @param [String] verb
      # @param [String] path
      # @param [Hash] payload
      # @return [Hash, Array]
      def api_request(verb, path, payload = nil, headers = token_header)
        args = [verb, "#{gitlab_api_url}/projects/#{GITLAB_PROJECT_ID}/#{path}", payload, headers].compact
        response = public_send(*args)
        raise "Api request to #{path} failed! Body: #{response.body}" unless success?(response.code)
        return {} if response.body.empty?

        parse_body(response)
      end
    end
  end
end

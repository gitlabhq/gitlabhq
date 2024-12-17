# frozen_string_literal: true

module QA
  module Resource
    class MergeRequest < Issuable
      include ApprovalConfiguration

      attr_accessor :approval_rules,
        :source_branch,
        :target_new_branch,
        :update_existing_file,
        :assignee,
        :milestone,
        :labels,
        :file_name,
        :file_content,
        :reviewer_ids

      attr_writer :no_preparation,
        :wait_for_merge,
        :template

      attributes :iid,
        :title,
        :description,
        :merge_when_pipeline_succeeds,
        :detailed_merge_status,
        :prepared_at,
        :state,
        :reviewers

      attribute :project do
        Project.fabricate_via_api! do |resource|
          resource.name = 'project-with-merge-request'
          resource.initialize_with_readme = true
          resource.api_client = api_client
        end
      end

      attribute :target_branch do
        project.default_branch
      end

      attribute :target do
        Repository::Commit.fabricate_via_api! do |resource|
          resource.project = project
          resource.api_client = api_client
          resource.commit_message = 'This is a test commit'
          resource.add_files([{ file_path: "file-#{SecureRandom.hex(8)}.txt", content: 'MR init' }])
          resource.branch = target_branch

          resource.start_branch = project.default_branch if target_branch != project.default_branch
        end
      end

      attribute :source do
        Repository::Commit.fabricate_via_api! do |resource|
          resource.project = project
          resource.api_client = api_client
          resource.commit_message = 'This is a test commit'
          resource.branch = source_branch
          resource.start_branch = target_branch

          files = [{ file_path: file_name, content: file_content }]
          update_existing_file ? resource.update_files(files) : resource.add_files(files)
        end
      end

      def initialize
        @approval_rules = nil
        @title = 'QA test - merge request'
        @description = 'This is a test merge request'
        @source_branch = "qa-test-feature-#{SecureRandom.hex(8)}"
        @assignee = nil
        @milestone = nil
        @labels = []
        @file_name = "added_file-#{SecureRandom.hex(8)}.txt"
        @file_content = "File Added"
        @target_new_branch = true
        @update_existing_file = false
        @no_preparation = false
        @wait_for_merge = true
      end

      def fabricate!
        return fabricate_large_merge_request if large_setup?

        populate_target_and_source_if_required

        project.visit!
        Flow::MergeRequest.create_new(source_branch: source_branch)
        Page::MergeRequest::New.perform do |new_page|
          new_page.fill_title(@title)
          new_page.choose_template(@template) if @template
          new_page.fill_description(@description) if @description && !@template
          new_page.choose_milestone(@milestone) if @milestone
          new_page.assign_to_me if @assignee == 'me'
          labels.each do |label|
            new_page.select_label(label)
          end
          new_page.add_approval_rules(approval_rules) if approval_rules

          new_page.create_merge_request
        end
      end

      def fabricate_via_api!
        return fabricate_large_merge_request if large_setup?

        resource_web_url(api_get)
      rescue ResourceNotFoundError, NoValueError # rescue if iid not populated
        populate_target_and_source_if_required

        url = super
        wait_for_preparation
        url
      end

      def api_merge_path
        "/projects/#{project.id}/merge_requests/#{iid}/merge"
      end

      def api_get_path
        "/projects/#{project.id}/merge_requests/#{iid}"
      end

      def api_post_path
        "/projects/#{project.id}/merge_requests"
      end

      def api_reviewers_path
        "#{api_get_path}/reviewers"
      end

      def api_approve_path
        "#{api_get_path}/approve"
      end

      def api_post_body
        {
          description: description,
          source_branch: source_branch,
          target_branch: target_branch,
          title: title,
          reviewer_ids: reviewer_ids,
          labels: labels.join(",")
        }
      end

      # Get merge request reviews
      #
      # @return [Array<Hash>]
      def reviews
        parse_body(api_get_from(api_reviewers_path))
      end

      def api_merge_request_notes_path
        "#{api_get_path}/notes"
      end

      # Get the merge request notes
      #
      # @return [Array<Hash>]
      def notes
        QA::Runtime::Logger.info("Getting comments from MR: #{api_merge_request_notes_path}")

        response = get(Runtime::API::Request.new(api_client, api_merge_request_notes_path).url)

        unless response.code == HTTP_STATUS_OK
          raise ResourceQueryError, "Could not get comments form MR: (#{response.code}): `#{response}`."
        end

        parse_body(response)
      end

      def merge_via_api!
        QA::Runtime::Logger.info("Merging via PUT #{api_merge_path}")

        wait_until_mergable

        Support::Retrier.retry_on_exception(max_attempts: 10, sleep_interval: 5) do
          response = put(Runtime::API::Request.new(api_client, api_merge_path).url)

          unless response.code == HTTP_STATUS_OK
            raise ResourceUpdateFailedError, "Could not merge. Request returned (#{response.code}): `#{response}`."
          end

          result = parse_body(response)

          project.wait_for_merge(result[:title]) if @wait_for_merge

          result
        end
      end

      # Approve merge request
      #
      # Due to internal implementation of api client, project needs to have
      # setting 'Prevent approval by author' set to false since we use same user that created merge request which
      # is set through approval configuration
      #
      # @return [void]
      def approve
        api_post_to(api_approve_path, {})
      end

      def fabricate_large_merge_request
        # requires admin access
        QA::Support::Helpers::ImportSource.enable(%w[gitlab_project])
        Flow::Login.sign_in

        @project = Resource::ImportProject.fabricate_via_browser_ui!
        # Setting the name here, since otherwise some tests will look for an existing file in
        # the project without ever knowing what is in it.
        @file_name = "added_file-00000000.txt"
        @source_branch = "large_merge_request"
        @web_url = "#{project.web_url}/-/merge_requests/1"
      end

      # Return subset of fields for comparing merge requests
      #
      # @return [Hash]
      def comparable
        reload! if api_response.nil?

        api_resource.except(
          :id,
          :web_url,
          :project_id,
          :source_project_id,
          :target_project_id,
          :detailed_merge_status,
          # we consider mr to still be the same even if users changed
          :author,
          :reviewers,
          :assignees,
          # these can differ depending on user fetching mr
          :user,
          :subscribed,
          :first_contribution
        ).merge({ references: api_resource[:references].except(:full) })
      end

      private

      def large_setup?
        Runtime::Scenario.large_setup?
      rescue ArgumentError
        false
      end

      def transform_api_resource(api_resource)
        raise ResourceNotFoundError if api_resource.blank?

        super(api_resource)
      end

      # Create source and target and commits if necessary
      #
      # @return [void]
      def populate_target_and_source_if_required
        return if @no_preparation

        populate(:target) if create_target?
        populate(:source)
      end

      # Check if target needs to be created
      #
      # Return false if project was already initialized and mr target is default branch
      # Return false if target_new_branch is explicitly set to false
      #
      # @return [Boolean]
      def create_target?
        !(project.initialize_with_readme && target_branch == project.default_branch) && target_new_branch
      end

      # Wait until the merge request can be merged. Raises WaitExceededError if the MR can't be merged within 60 seconds
      #
      # @return [void]
      def wait_until_mergable
        return if Support::Waiter.wait_until(sleep_interval: 1, raise_on_failure: false, log: false) do
          reload!.detailed_merge_status == 'mergeable'
        end

        raise Support::Repeater::WaitExceededError,
          "Timed out waiting for merge of MR with id '#{iid}'. Final status was '#{detailed_merge_status}'"
      end

      # Wait until the merge request is prepared. Raises WaitExceededError if the MR is not prepared within 60 seconds
      # https://docs.gitlab.com/ee/api/merge_requests.html#preparation-steps
      #
      # @return [void]
      def wait_for_preparation
        return if Support::Waiter.wait_until(sleep_interval: 1, raise_on_failure: false, log: false) do
          reload!.prepared_at
        end

        raise Support::Repeater::WaitExceededError, "Timed out waiting for MR with id '#{iid}' to be prepared."
      end
    end
  end
end

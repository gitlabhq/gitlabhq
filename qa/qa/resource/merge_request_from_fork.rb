# frozen_string_literal: true

module QA
  module Resource
    # Merge request created from fork
    #
    class MergeRequestFromFork < MergeRequest
      attribute :fork do
        Fork.fabricate_via_api!
      end

      attribute :project do
        fork.upstream
      end

      attribute :source do
        Repository::Commit.fabricate_via_api! do |resource|
          resource.project = fork
          resource.api_client = api_client
          resource.commit_message = 'This is a test commit'
          resource.add_files([{ file_path: "file-#{SecureRandom.hex(8)}.txt", content: 'MR init' }])
          resource.branch = fork.default_branch
        end
      end

      def fabricate!
        populate(:source)

        fork.visit!

        # Ensure we are signed in as fork user and create the MR
        Flow::Login.sign_in_unless_signed_in(user: fork.user)
        Page::Project::Show.perform(&:new_merge_request)
        Page::MergeRequest::New.perform(&:create_merge_request)
        Support::Waiter.wait_until(message: 'Waiting for fork icon to appear') do
          Page::MergeRequest::Show.perform(&:has_fork_icon?)
        end
        mr_url = current_url

        # Sign back in as original user
        Flow::Login.sign_in
        visit(mr_url)
      end

      # Post path targeting fork project rather than target
      #
      # @return [String]
      def api_post_path
        "/projects/#{fork.id}/merge_requests"
      end

      def api_post_body
        super.merge({
          target_project_id: project.id,
          source_branch: fork.default_branch,
          target_branch: project.default_branch
        })
      end

      private

      # Api client for mr creations
      # MR needs to be created using same api client used for fork creation to have the correct access rights
      #
      # @return [Runtime::API::Client]
      def api_client
        @api_client ||= fork.api_client
      end

      # Target is upstream, in fork workflow it must not be populated
      #
      # @return [Boolean]
      def create_target?
        false
      end

      # Push the source commit, then wait until the upstream can compute a diff against the fork before
      # creating the merge request.
      #
      # A fork reporting `import_status: finished` does not guarantee its repository is consistent for
      # cross-project operations. Creating the merge request too early can persist a merge request diff with a
      # blank base SHA (an uncomputable merge base), which crashes MR preparation and leaves the MR
      # permanently unprepared.
      # See https://gitlab.com/gitlab-org/quality/test-failure-issues/-/work_items/43197
      #
      # @return [void]
      def populate_target_and_source_if_required
        super

        return if @no_preparation

        wait_until_comparable_with_upstream
      end

      # Poll the cross-project compare endpoint until the upstream can compute a merge-base based comparison
      # against the fork's source branch. This exercises the same cross-repository merge base that merge
      # request diff preparation relies on, so a successful comparison means the fork is ready for the MR.
      #
      # @return [void]
      def wait_until_comparable_with_upstream
        Support::Retrier.retry_until(
          max_duration: 60,
          sleep_interval: 3,
          message: "Wait for fork '#{fork.path_with_namespace}' to be comparable with upstream"
        ) do
          response = get(request_url(
            "/projects/#{fork.id}/repository/compare",
            from: project.default_branch,
            to: fork.default_branch,
            from_project_id: project.id,
            straight: false
          ))

          Runtime::Logger.debug(
            "Fork readiness compare returned #{response.code} (fork: #{fork.id}, upstream: #{project.id})"
          )

          response.code == HTTP_STATUS_OK
        end
      end
    end
  end
end

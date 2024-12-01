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
    end
  end
end

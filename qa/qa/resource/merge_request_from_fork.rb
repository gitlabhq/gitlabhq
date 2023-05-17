# frozen_string_literal: true

module QA
  module Resource
    class MergeRequestFromFork < MergeRequest
      attr_accessor :fork_branch

      attribute :fork do
        Fork.fabricate_via_browser_ui!
      end

      attribute :push do
        Repository::ProjectPush.fabricate! do |resource|
          resource.project = fork.project
          resource.branch_name = fork_branch
          resource.file_name = "file2-#{SecureRandom.hex(8)}.txt"
          resource.user = fork.user
        end
      end

      def fabricate!
        populate(:push)

        fork.project.visit!

        # Ensure we are signed in as fork user and create the MR
        Flow::Login.sign_in_unless_signed_in(user: fork.user)
        Page::Project::Show.perform(&:new_merge_request)
        Page::MergeRequest::New.perform(&:create_merge_request)
        Support::WaitForRequests.wait_for_requests
        mr_url = current_url

        # Sign back in as original user
        Flow::Login.sign_in
        visit(mr_url)
      end

      def fabricate_via_api!
        raise NotImplementedError
      end
    end
  end
end

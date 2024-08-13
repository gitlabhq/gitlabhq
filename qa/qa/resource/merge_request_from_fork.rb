# frozen_string_literal: true

module QA
  module Resource
    class MergeRequestFromFork < MergeRequest
      attribute :fork do
        Fork.fabricate_via_api!
      end

      attribute :project do
        fork.project
      end

      attribute :source do
        Repository::Commit.fabricate_via_api! do |resource|
          resource.project = project
          resource.api_client = api_client
          resource.commit_message = 'This is a test commit'
          resource.add_files([{ file_path: "file-#{SecureRandom.hex(8)}.txt", content: 'MR init' }])
          resource.branch = project.default_branch
        end
      end

      def fabricate!
        populate(:source)

        fork.project.visit!

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

      def api_post_body
        super.merge({
          target_project_id: upstream.id,
          source_branch: project.default_branch,
          target_branch: upstream.default_branch
        })
      end

      def fabricate_via_api!
        populate(:source)

        super
      end

      # Fabricated mr needs to be fetched from upstream project rather than source project
      #
      # @return [String]
      def api_get_path
        "/projects/#{upstream.id}/merge_requests/#{iid}"
      end

      private

      def api_client
        fork.api_client
      end

      # Target is upstream, in fork workflow it must not be populated
      #
      # @return [Boolean]
      def create_target?
        false
      end

      def upstream
        fork.upstream
      end
    end
  end
end

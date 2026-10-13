# frozen_string_literal: true

module QA
  RSpec.describe 'Create', feature_category: :code_review_workflow do
    describe 'new merge request for a pushed branch' do
      let(:branch_name) { "merge-request-test-#{SecureRandom.hex(8)}" }
      let(:title) { "Merge from push event notification test #{SecureRandom.hex(8)}" }
      let(:project) { create(:project, :with_readme) }

      before do
        Flow::Login.sign_in
      end

      # Opens the new MR page directly; the push banner depends on a cached push event.
      def create_merge_request_for_branch
        page.visit("#{project.web_url}/-/merge_requests/new?merge_request[source_branch]=#{branch_name}")

        Page::MergeRequest::New.perform do |merge_request|
          merge_request.fill_title(title)
          merge_request.create_merge_request
        end
      end

      it 'after a push via the git CLI creates a merge request' do
        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = project
          push.branch_name = branch_name
        end

        create_merge_request_for_branch

        Page::MergeRequest::Show.perform do |merge_request|
          expect(merge_request).to have_title(title)
        end
      end

      it 'after a push via the API creates a merge request' do
        commit = create(:commit,
          project: project,
          branch: branch_name,
          start_branch: project.default_branch,
          actions: [
            { action: 'create', file_path: "file-#{SecureRandom.hex(8)}.txt", content: 'MR init' }
          ])

        project.wait_for_push(commit.commit_message)

        create_merge_request_for_branch

        Page::MergeRequest::Show.perform do |merge_request|
          expect(merge_request).to have_title(title)
        end
      end
    end
  end
end

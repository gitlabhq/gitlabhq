# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Cherry picking a commit', :smoke, product_group: :code_review do
      let(:file_name) { "secret_file.md" }
      let(:project) { create(:project, :with_readme) }
      let(:commit) do
        create(:commit,
          project: project,
          branch: 'development',
          start_branch: project.default_branch,
          commit_message: 'Add new file', actions: [
            { action: 'create', file_path: file_name, content: 'pssst!' }
          ])
      end

      before do
        Flow::Login.sign_in
        commit.visit!
      end

      it 'creates a merge request', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347710' do
        Page::Project::Commit::Show.perform(&:cherry_pick_commit)
        Page::MergeRequest::New.perform(&:create_merge_request)

        Page::MergeRequest::Show.perform do |merge_request|
          merge_request.click_diffs_tab
          expect(merge_request).to have_file(file_name)
        end
      end
    end
  end
end

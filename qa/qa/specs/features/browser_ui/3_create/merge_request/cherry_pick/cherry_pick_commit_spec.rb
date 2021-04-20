# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Cherry picking a commit' do
      let(:file_name) { "secret_file.md" }

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'project'
          project.initialize_with_readme = true
        end
      end

      let(:commit) do
        Resource::Repository::Commit.fabricate_via_api! do |commit|
          commit.project = project
          commit.branch = "development"
          commit.start_branch = project.default_branch
          commit.commit_message = 'Add new file'
          commit.add_files([
            { file_path: file_name, content: 'pssst!' }
          ])
        end
      end

      before do
        Flow::Login.sign_in
        commit.visit!
      end

      it 'creates a merge request', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1752' do
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

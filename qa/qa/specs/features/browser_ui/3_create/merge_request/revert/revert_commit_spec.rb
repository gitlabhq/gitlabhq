# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Reverting a commit' do
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

      it 'creates a merge request', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1784' do
        Page::Project::Commit::Show.perform(&:revert_commit)
        Page::MergeRequest::New.perform(&:create_merge_request)

        Page::MergeRequest::Show.perform do |merge_request|
          merge_request.click_diffs_tab
          expect(merge_request).to have_file(file_name)
        end
      end

      after do
        project.remove_via_api!
      end
    end
  end
end

# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Branch with unusual name' do
      let(:branch_name) { 'unUsually/named#br--anch' }
      let(:project) do
        Resource::Project.fabricate_via_api! do |resource|
          resource.name = 'unusually-named-branch-project'
          resource.initialize_with_readme = true
        end
      end

      before do
        Flow::Login.sign_in
      end

      context 'when branch name contains slash, hash, double dash, and capital letter' do
        it 'renders repository file tree correctly', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1780' do
          Resource::Repository::Commit.fabricate_via_api! do |commit|
            commit.project = project
            commit.branch = branch_name
            commit.start_branch = project.default_branch
            commit.commit_message = 'Add new file'
            commit.add_files([
                                 { file_path: 'test-folder/test-file.md', content: 'new content' }
                             ])
          end

          project.visit!

          Page::Project::Show.perform do |show|
            show.switch_to_branch(branch_name)
            show.click_file('test-folder')

            expect(show).to have_file('test-file.md')

            show.click_file('test-file.md')

            expect(show).to have_content('new content')
          end
        end
      end
    end
  end
end

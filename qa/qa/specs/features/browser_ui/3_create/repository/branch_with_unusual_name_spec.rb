# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Branch with unusual name', product_group: :source_code do
      let(:branch_name) { 'unUsually/named#br--anch' }
      let(:project) { create(:project, :with_readme, name: 'unusually-named-branch-project') }

      before do
        Flow::Login.sign_in
      end

      context 'when branch name contains slash, hash, double dash, and capital letter' do
        it 'renders repository file tree correctly', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347715' do
          create(:commit,
            project: project,
            branch: branch_name,
            start_branch: project.default_branch,
            commit_message: 'Add new file', actions: [
              { action: 'create', file_path: 'test-folder/test-file.md', content: 'new content' }
            ])

          project.visit!

          Page::Project::Show.perform do |show|
            show.switch_to_branch(branch_name)

            # To prevent false positives: https://gitlab.com/gitlab-org/gitlab/-/issues/383863
            expect(show).to have_no_content('An error occurred')

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

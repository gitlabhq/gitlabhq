# frozen_string_literal: true

module QA
  RSpec.describe 'Create' do
    describe 'Source editor toolbar preview', product_group: :source_code do
      let(:project) { create(:project, :with_readme, name: 'empty-project-with-md') }
      let(:edited_readme_content) { 'Here is the edited content.' }

      before do
        Flow::Login.sign_in
      end

      it 'can preview markdown side-by-side while editing',
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/367749',
        quarantine: {
          only: { job: 'gdk' },
          type: 'test_environment',
          issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/466663'
        } do
        project.visit!
        Page::Project::Show.perform do |project|
          project.click_file('README.md')
        end

        Page::File::Show.perform(&:click_edit)

        Page::File::Edit.perform do |file|
          file.remove_content
          file.add_content("# #{edited_readme_content}")
          file.preview
          expect(file.has_markdown_preview?('h1', edited_readme_content)).to be true
          file.click_commit_changes_in_header
          file.commit_changes_through_modal
        end

        Page::File::Show.perform do |file|
          aggregate_failures 'file details' do
            expect(file).to have_notice('Your changes have been committed successfully.')
            expect(file).to have_file_content(edited_readme_content)
          end
        end
      end
    end
  end
end

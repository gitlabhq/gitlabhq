# frozen_string_literal: true
# tagged transient due to feature-flag caching flakiness. Remove tag along with feature flag removal.
module QA
  RSpec.describe 'Create', feature_flag: { name: 'source_editor_toolbar', scope: :global } do
    describe 'Source editor toolbar preview', product_group: :source_code do
      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'empty-project-with-md'
          project.initialize_with_readme = true
        end
      end

      let(:edited_readme_content) { 'Here is the edited content.' }

      before do
        Runtime::Feature.enable(:source_editor_toolbar)
        Flow::Login.sign_in
      end

      after do
        Runtime::Feature.disable(:source_editor_toolbar)
      end

      it 'can preview markdown side-by-side while editing',
      testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/367749' do
        project.visit!
        Page::Project::Show.perform do |project|
          project.click_file('README.md')
        end

        Page::File::Show.perform(&:click_edit)

        # wait_until required due to feature_caching. Remove along with feature flag removal.
        Page::File::Edit.perform do |file|
          Support::Waiter.wait_until(sleep_interval: 2, max_duration: 60, reload_page: page,
                                     retry_on_exception: true) do
            expect(file).to have_element(:editor_toolbar_button)
          end
          file.remove_content
          file.click_editor_toolbar
          file.add_content('# ' + edited_readme_content)
          file.wait_for_markdown_preview('h1', edited_readme_content)
          file.commit_changes
        end

        Page::File::Show.perform do |file|
          aggregate_failures 'file details' do
            expect(file).to have_notice('Your changes have been successfully committed.')
            expect(file).to have_file_content(edited_readme_content)
          end
        end
      end
    end
  end
end

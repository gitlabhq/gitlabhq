# frozen_string_literal: true

module QA
  RSpec.describe 'Plan' do
    describe 'Issue creation' do
      let(:closed_issue) { Resource::Issue.fabricate_via_api! }

      before do
        Flow::Login.sign_in
      end

      it 'creates an issue', :smoke, :reliable, testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1167' do
        issue = Resource::Issue.fabricate_via_browser_ui!

        Page::Project::Menu.perform(&:click_issues)

        Page::Project::Issue::Index.perform do |index|
          expect(index).to have_issue(issue)
        end
      end

      it 'closes an issue', :smoke, testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1085' do
        closed_issue.visit!

        Page::Project::Issue::Show.perform do |issue_page|
          issue_page.click_close_issue_button

          expect(issue_page).to have_element(:reopen_issue_button)
        end

        Page::Project::Menu.perform(&:click_issues)
        Page::Project::Issue::Index.perform do |index|
          expect(index).not_to have_issue(closed_issue)

          index.click_closed_issues_link

          expect(index).to have_issue(closed_issue)
        end
      end

      context 'when using attachments in comments', :smoke, :object_storage do
        let(:gif_file_name) { 'banana_sample.gif' }
        let(:file_to_attach) do
          File.absolute_path(File.join('qa', 'fixtures', 'designs', gif_file_name))
        end

        before do
          Resource::Issue.fabricate_via_api!.visit!
        end

        it 'comments on an issue with an attachment', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/393' do
          Page::Project::Issue::Show.perform do |show|
            show.comment('See attached banana for scale', attachment: file_to_attach)

            expect(show.noteable_note_item.find("img[src$='#{gif_file_name}']")).to be_visible
          end
        end
      end

      context 'when using custom issue templates' do
        let(:template_name) { 'custom_issue_template'}
        let(:template_content) { 'This is a custom issue template test' }

        let(:template_project) do
          Resource::Project.fabricate_via_api! do |project|
            project.name = "custom-issue-template-project-#{SecureRandom.hex(8)}"
            project.initialize_with_readme = true
          end
        end

        before do
          Resource::Repository::Commit.fabricate_via_api! do |commit|
            commit.project = template_project
            commit.commit_message = 'Add custom issue template'
            commit.add_files([
              {
                file_path: ".gitlab/issue_templates/#{template_name}.md",
                content: template_content
              }
            ])
          end
        end

        it 'creates an issue via custom template', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1229' do
          Resource::Issue.fabricate_via_browser_ui! do |issue|
            issue.project = template_project
            issue.template = template_name
          end

          Page::Project::Issue::Show.perform do |issue_page|
            expect(issue_page).to have_content(template_content)
          end
        end
      end
    end
  end
end

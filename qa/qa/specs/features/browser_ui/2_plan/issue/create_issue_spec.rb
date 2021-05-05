# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', :smoke do
    describe 'Issue creation' do
      let(:closed_issue) { Resource::Issue.fabricate_via_api! }

      before do
        Flow::Login.sign_in
      end

      it 'creates an issue', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1793' do
        issue = Resource::Issue.fabricate_via_browser_ui!

        Page::Project::Menu.perform(&:click_issues)

        Page::Project::Issue::Index.perform do |index|
          expect(index).to have_issue(issue)
        end
      end

      it 'closes an issue', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1792' do
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

      context 'when using attachments in comments', :object_storage do
        let(:gif_file_name) { 'banana_sample.gif' }
        let(:file_to_attach) do
          File.absolute_path(File.join('qa', 'fixtures', 'designs', gif_file_name))
        end

        before do
          Resource::Issue.fabricate_via_api!.visit!
        end

        it 'comments on an issue with an attachment', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1742' do
          Page::Project::Issue::Show.perform do |show|
            show.comment('See attached banana for scale', attachment: file_to_attach)

            expect(show.noteable_note_item.find("img[src$='#{gif_file_name}']")).to be_visible
          end
        end
      end
    end
  end
end

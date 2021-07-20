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
        let(:png_file_name) { 'testfile.png' }
        let(:file_to_attach) do
          File.absolute_path(File.join('qa', 'fixtures', 'designs', png_file_name))
        end

        before do
          Resource::Issue.fabricate_via_api!.visit!
        end

        # The following example is excluded from running in `review-qa-smoke` job
        # as it proved to be flaky when running against Review App
        # See https://gitlab.com/gitlab-com/www-gitlab-com/-/issues/11568#note_621999351
        it 'comments on an issue with an attachment', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1742', except: { job: 'review-qa-smoke' } do
          Page::Project::Issue::Show.perform do |show|
            show.comment('See attached image for scale', attachment: file_to_attach)

            expect(show.noteable_note_item.find("img[src$='#{png_file_name}']")).to be_visible
          end
        end
      end
    end
  end
end

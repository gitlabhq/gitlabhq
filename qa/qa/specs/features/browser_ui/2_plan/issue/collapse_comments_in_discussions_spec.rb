# frozen_string_literal: true

module QA
  context 'Plan' do
    describe 'collapse comments in issue discussions' do
      let(:issue_title) { 'issue title' }

      it 'user collapses reply for comments in an issue' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)

        Resource::Issue.fabricate_via_browser_ui! do |issue|
          issue.title = issue_title
        end

        expect(page).to have_content(issue_title)

        Page::Project::Issue::Show.perform do |show_page|
          show_page.select_all_activities_filter
          show_page.start_discussion("My first discussion")
          expect(show_page).to have_content("My first discussion")

          show_page.reply_to_discussion("My First Reply")
          expect(show_page).to have_content("My First Reply")

          show_page.collapse_replies
          expect(show_page).to have_content("1 reply")
          expect(show_page).not_to have_content("My First Reply")

          show_page.expand_replies
          expect(show_page).to have_content("My First Reply")
          expect(show_page).not_to have_content("1 reply")
        end
      end
    end
  end
end

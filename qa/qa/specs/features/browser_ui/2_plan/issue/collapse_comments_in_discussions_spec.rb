# frozen_string_literal: true

module QA
  context 'Plan' do
    describe 'collapse comments in issue discussions' do
      let(:issue_title) { 'issue title' }

      it 'user collapses reply for comments in an issue' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)

        issue = Resource::Issue.fabricate_via_api! do |issue|
          issue.title = issue_title
        end

        issue.visit!

        expect(page).to have_content(issue_title)

        Page::Project::Issue::Show.perform do |show_page|
          my_first_discussion = "My first discussion"
          my_first_reply = "My First Reply"
          one_reply = "1 reply"

          show_page.select_all_activities_filter
          show_page.start_discussion(my_first_discussion)
          expect(show_page).to have_content(my_first_discussion)

          show_page.reply_to_discussion(my_first_reply)
          expect(show_page).to have_content(my_first_reply)

          show_page.collapse_replies
          expect(show_page).to have_content(one_reply)
          expect(show_page).not_to have_content(my_first_reply)

          show_page.expand_replies
          expect(show_page).to have_content(my_first_reply)
          expect(show_page).not_to have_content(one_reply)
        end
      end
    end
  end
end

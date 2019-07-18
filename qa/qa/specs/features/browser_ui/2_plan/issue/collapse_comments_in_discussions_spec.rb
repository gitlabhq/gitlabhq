# frozen_string_literal: true

module QA
  context 'Plan' do
    describe 'collapse comments in issue discussions' do
      let(:my_first_reply) { 'My first reply' }

      before do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)

        issue = Resource::Issue.fabricate_via_api! do |issue|
          issue.title = 'issue title'
        end

        issue.visit!

        Page::Project::Issue::Show.perform do |show_page|
          my_first_discussion = 'My first discussion'

          show_page.select_all_activities_filter
          show_page.start_discussion(my_first_discussion)
          page.assert_text(my_first_discussion)
          show_page.reply_to_discussion(my_first_reply)
          page.assert_text(my_first_reply)
        end
      end

      it 'user collapses and expands reply for comments in an issue' do
        Page::Project::Issue::Show.perform do |show_page|
          one_reply = "1 reply"

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

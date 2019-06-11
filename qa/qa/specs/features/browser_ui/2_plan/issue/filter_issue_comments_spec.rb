# frozen_string_literal: true

module QA
  context 'Plan' do
    describe 'filter issue comments activities' do
      let(:issue_title) { 'issue title' }

      it 'user filters comments and activities in an issue' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.act { sign_in_using_credentials }

        Resource::Issue.fabricate! do |issue|
          issue.title = issue_title
        end

        expect(page).to have_content(issue_title)

        Page::Project::Issue::Show.perform do |show_page|
          show_page.comment('/confidential', filter: :comments_only)
          show_page.comment('My own comment', filter: :comments_only)

          expect(show_page).not_to have_content("made the issue confidential")
          expect(show_page).to have_content("My own comment")

          show_page.select_all_activities_filter

          expect(show_page).to have_content("made the issue confidential")
          expect(show_page).to have_content("My own comment")

          show_page.select_history_only_filter

          expect(show_page).to have_content("made the issue confidential")
          expect(show_page).not_to have_content("My own comment")
        end
      end
    end
  end
end

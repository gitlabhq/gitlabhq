# frozen_string_literal: true

module QA
  context 'Plan' do
    describe 'filter issue comments activities' do
      let(:issue_title) { 'issue title' }

      it 'user filters comments and activities in an issue' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)

        issue = Resource::Issue.fabricate_via_api! do |issue|
          issue.title = issue_title
        end

        issue.visit!

        expect(page).to have_content(issue_title)

        Page::Project::Issue::Show.perform do |show_page|
          my_own_comment = "My own comment"
          made_the_issue_confidential = "made the issue confidential"

          show_page.comment('/confidential', filter: :comments_only)
          show_page.comment(my_own_comment, filter: :comments_only)

          expect(show_page).not_to have_content(made_the_issue_confidential)
          expect(show_page).to have_content(my_own_comment)

          show_page.select_all_activities_filter

          expect(show_page).to have_content(made_the_issue_confidential)
          expect(show_page).to have_content(my_own_comment)

          show_page.select_history_only_filter

          expect(show_page).to have_content(made_the_issue_confidential)
          expect(show_page).not_to have_content(my_own_comment)
        end
      end
    end
  end
end

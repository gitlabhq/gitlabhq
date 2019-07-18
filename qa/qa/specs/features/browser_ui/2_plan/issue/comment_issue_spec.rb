# frozen_string_literal: true

module QA
  context 'Plan' do
    describe 'Issue comments' do
      it 'user comments on an issue and edits the comment' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)

        issue = Resource::Issue.fabricate_via_api! do |issue|
          issue.title = 'issue title'
        end
        issue.visit!

        Page::Project::Issue::Show.perform do |issue_show_page|
          first_version_of_comment = 'First version of the comment'
          second_version_of_comment = 'Second version of the comment'

          issue_show_page.comment(first_version_of_comment)

          expect(issue_show_page).to have_content(first_version_of_comment)

          issue_show_page.edit_comment(second_version_of_comment)

          expect(issue_show_page).to have_content(second_version_of_comment)
          expect(issue_show_page).not_to have_content(first_version_of_comment)
        end
      end
    end
  end
end

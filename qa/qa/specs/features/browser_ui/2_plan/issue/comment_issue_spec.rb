# frozen_string_literal: true

module QA
  context 'Plan' do
    describe 'Issue comments' do
      before do
        Flow::Login.sign_in

        issue = Resource::Issue.fabricate_via_api! do |issue|
          issue.title = 'issue title'
        end
        issue.visit!
      end

      it 'user comments on an issue and edits the comment' do
        Page::Project::Issue::Show.perform do |show|
          first_version_of_comment = 'First version of the comment'
          second_version_of_comment = 'Second version of the comment'

          show.comment(first_version_of_comment)

          expect(show).to have_content(first_version_of_comment)

          show.edit_comment(second_version_of_comment)

          expect(show).to have_content(second_version_of_comment)
          expect(show).not_to have_content(first_version_of_comment)
        end
      end
    end
  end
end

# frozen_string_literal: true

module QA
  context 'Plan' do
    describe 'filter issue comments activities' do
      let(:issue_title) { 'issue title' }

      before do
        Flow::Login.sign_in

        issue = Resource::Issue.fabricate_via_api! do |issue|
          issue.title = issue_title
        end

        issue.visit!
      end

      it 'user filters comments and activities in an issue' do
        Page::Project::Issue::Show.perform do |show|
          my_own_comment = "My own comment"
          made_the_issue_confidential = "made the issue confidential"

          show.comment('/confidential', filter: :comments_only)
          show.comment(my_own_comment, filter: :comments_only)

          expect(show).not_to have_content(made_the_issue_confidential)
          expect(show).to have_content(my_own_comment)

          show.select_all_activities_filter

          expect(show).to have_content(made_the_issue_confidential)
          expect(show).to have_content(my_own_comment)

          show.select_history_only_filter

          expect(show).to have_content(made_the_issue_confidential)
          expect(show).not_to have_content(my_own_comment)
        end
      end
    end
  end
end

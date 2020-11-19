# frozen_string_literal: true

module QA
  RSpec.describe 'Plan' do
    describe 'filter issue comments activities' do
      before do
        Flow::Login.sign_in

        Resource::Issue.fabricate_via_api!.visit!
      end

      it 'filters comments and activities in an issue', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/425' do
        Page::Project::Issue::Show.perform do |show|
          my_own_comment = "My own comment"
          made_the_issue_confidential = "made the issue confidential"

          show.comment('/confidential', filter: :comments_only)
          show.comment(my_own_comment, filter: :comments_only)

          expect(show).not_to have_content(made_the_issue_confidential)
          expect(show).to have_comment(my_own_comment)

          show.select_all_activities_filter

          expect(show).to have_system_note(made_the_issue_confidential)
          expect(show).to have_comment(my_own_comment)

          show.select_history_only_filter

          expect(show).to have_system_note(made_the_issue_confidential)
          expect(show).not_to have_content(my_own_comment)
        end
      end
    end
  end
end

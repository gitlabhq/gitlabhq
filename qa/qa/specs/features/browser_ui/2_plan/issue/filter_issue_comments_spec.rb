# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', :smoke, feature_category: :team_planning do
    describe 'filter issue comments activities' do
      before do
        Flow::Login.sign_in

        create(:issue).visit!
      end

      it(
        'filters comments and activities in an issue', :aggregate_failures,
        testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347948',
        quarantine: {
          issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/534698',
          type: :flaky
        }
      ) do
        work_item_enabled = Page::Project::Issue::Show.perform(&:work_item_enabled?)
        page_type = work_item_enabled ? Page::Project::WorkItem::Show : Page::Project::Issue::Show

        page_type.perform do |show|
          my_own_comment = "My own comment"
          made_the_issue_confidential = "made the issue confidential"

          show.comment('/confidential', filter: :comments_only)
          show.comment(my_own_comment, filter: :comments_only)

          expect { show }.not_to eventually_have_content(made_the_issue_confidential)
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

# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', feature_category: :team_planning do
    describe 'issue suggestions' do
      let(:issue_title) { 'Issue Lists are awesome' }

      before do
        Flow::Login.sign_in

        create(:issue, title: issue_title).project.visit!
      end

      it 'shows issue suggestions when creating a new issue', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347995' do
        Page::Project::Menu.perform(&:go_to_new_issue)

        work_item_enabled = Page::Project::Issue::Index.perform(&:work_item_enabled?)
        page_type = work_item_enabled ? Page::Project::WorkItem::New : Page::Project::Issue::New

        page_type.perform do |new_page|
          new_page.fill_title("issue")

          expect(new_page).to have_content(issue_title)

          new_page.fill_title("Issue Board")

          expect(new_page).not_to have_content(issue_title)
        end
      end
    end
  end
end

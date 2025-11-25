# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', feature_category: :team_planning do
    describe 'Issues list' do
      let(:project) { create(:project, name: 'project-to-test-export-issues-as-csv') }

      before do
        Flow::Login.sign_in

        create_list(:issue, 2, project: project)

        project.visit!
        Page::Project::Menu.perform(&:go_to_work_items)
      end

      it 'successfully exports issues list as CSV', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347968' do
        Page::Project::WorkItem::Index.perform do |index|
          index.click_work_items_list_more_actions_dropdown

          index.click_export_as_csv_button

          expect(index.export_issues_modal).to have_content('2 issues selected')

          index.click_export_issues_button

          expect(index).to have_content(/Your CSV export request has succeeded. The result will be emailed to (\S+)./)
        end
      end
    end
  end
end

# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', product_group: :project_management do
    describe 'Issues list' do
      let(:project) { create(:project, name: 'project-to-test-export-issues-as-csv') }

      before do
        Flow::Login.sign_in

        create_list(:issue, 2, project: project)

        project.visit!
        Page::Project::Menu.perform(&:go_to_issues)
      end

      it 'successfully exports issues list as CSV', testcase: 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347968' do
        Page::Project::Issue::Index.perform do |index|
          index.click_issues_list_more_actions_dropdown

          index.click_export_as_csv_button

          expect(index.export_issues_modal).to have_content('2 issues selected')

          index.click_export_issues_button

          expect(index).to have_content(/Your CSV export has started. It will be emailed to (\S+) when complete./)
        end
      end
    end
  end
end

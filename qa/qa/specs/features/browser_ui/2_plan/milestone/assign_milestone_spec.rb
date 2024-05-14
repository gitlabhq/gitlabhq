# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', :smoke, product_group: :project_management do
    describe 'Milestones' do
      include Support::Dates

      let(:start_date) { current_date_yyyy_mm_dd }
      let(:due_date) { next_month_yyyy_mm_dd }

      let(:group) { create(:group, name: "group-to-test-milestones-#{SecureRandom.hex(4)}") }

      let(:project) { create(:project, name: "project-to-test-milestones-#{SecureRandom.hex(4)}", group: group) }

      let(:issue) { create(:issue, project: project) }

      before do
        Flow::Login.sign_in
      end

      shared_examples 'when assigned to existing issue' do |testcase|
        it 'is assigned', testcase: testcase do
          issue.visit!

          Page::Project::Issue::Show.perform do |existing_issue|
            existing_issue.assign_milestone(milestone)

            expect(existing_issue).to have_milestone(milestone.title)
          end
        end
      end

      shared_examples 'when assigned to new issue' do |testcase|
        it 'is assigned', testcase: testcase do
          Resource::Issue.fabricate_via_browser_ui! do |new_issue|
            new_issue.project = project
            new_issue.milestone = milestone
          end

          Page::Project::Issue::Show.perform do |issue|
            expect(issue).to have_milestone(milestone.title)
          end
        end
      end

      context 'Group milestone' do
        let(:milestone) { create(:group_milestone, group: group, start_date: start_date, due_date: due_date) }

        it_behaves_like 'when assigned to existing issue', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347964'
        it_behaves_like 'when assigned to new issue', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347965'
      end

      context 'Project milestone' do
        let(:milestone) { create(:project_milestone, project: project, start_date: start_date, due_date: due_date) }

        it_behaves_like 'when assigned to existing issue', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347962'
        it_behaves_like 'when assigned to new issue', 'https://gitlab.com/gitlab-org/gitlab/-/quality/test_cases/347963'
      end
    end
  end
end

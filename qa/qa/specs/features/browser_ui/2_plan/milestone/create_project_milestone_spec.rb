# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', :reliable do
    describe 'Project milestone' do
      include Support::Dates

      let(:title) { 'Project milestone' }
      let(:description) { 'This issue tests out project milestones.' }
      let(:start_date) { current_date_yyyy_mm_dd }
      let(:due_date) { next_month_yyyy_mm_dd }

      before do
        Flow::Login.sign_in
      end

      it 'creates a project milestone', testcase: 'https://gitlab.com/gitlab-org/quality/testcases/-/issues/1165' do
        project_milestone = Resource::ProjectMilestone.fabricate_via_browser_ui! do |milestone|
          milestone.title = title
          milestone.description = description
          milestone.start_date = start_date
          milestone.due_date = due_date
        end

        Page::Project::Menu.perform(&:go_to_milestones)
        Page::Project::Milestone::Index.perform do |milestone_list|
          expect(milestone_list).to have_milestone(project_milestone)

          milestone_list.click_milestone(project_milestone)
        end

        Page::Milestone::Show.perform do |milestone|
          expect(milestone).to have_element(:milestone_title_content, text: title)
          expect(milestone).to have_element(:milestone_description_content, text: description)
          expect(milestone).to have_start_date(start_date)
          expect(milestone).to have_due_date(due_date)
        end
      end
    end
  end
end

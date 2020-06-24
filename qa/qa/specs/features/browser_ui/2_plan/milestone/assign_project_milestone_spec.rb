# frozen_string_literal: true

module QA
  context 'Plan' do
    describe 'Project milestone' do
      include Support::Dates

      let(:title) { 'Project milestone' }
      let(:start_date) { current_date_yyyy_mm_dd }
      let(:due_date) { next_month_yyyy_mm_dd }

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'project-to-test-milestones'
        end
      end

      let(:issue) do
        Resource::Issue.fabricate_via_api! do |issue|
          issue.project = project
        end
      end

      let(:project_milestone) do
        Resource::ProjectMilestone.fabricate_via_api! do |milestone|
          milestone.project = project
          milestone.start_date = start_date
          milestone.due_date = due_date
        end
      end

      before do
        Flow::Login.sign_in
      end

      it 'assigns a project milestone to an existing issue' do
        issue.visit!

        Page::Project::Issue::Show.perform do |existing_issue|
          existing_issue.assign_milestone(project_milestone)

          expect(existing_issue).to have_milestone(project_milestone.title)
        end
      end

      it 'assigns a project milestone to a new issue' do
        Resource::Issue.fabricate_via_browser_ui! do |issue|
          issue.project = project
          issue.milestone = project_milestone
        end

        Page::Project::Issue::Show.perform do |issue|
          expect(issue).to have_milestone(project_milestone.title)
        end
      end
    end
  end
end

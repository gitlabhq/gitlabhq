# frozen_string_literal: true

module QA
  RSpec.describe 'Plan', :reliable do
    describe 'Milestones' do
      include Support::Dates

      let(:start_date) { current_date_yyyy_mm_dd }
      let(:due_date) { next_month_yyyy_mm_dd }

      let(:group) do
        Resource::Group.fabricate_via_api! do |group|
          group.name = 'group-to-test-milestones'
        end
      end

      let(:project) do
        Resource::Project.fabricate_via_api! do |project|
          project.name = 'project-to-test-milestones'
          project.group = group
        end
      end

      let(:issue) do
        Resource::Issue.fabricate_via_api! do |issue|
          issue.project = project
        end
      end

      before do
        Flow::Login.sign_in
      end

      shared_examples 'milestone assigned to existing issue' do
        it 'is assigned to an existing issue' do
          issue.visit!

          Page::Project::Issue::Show.perform do |existing_issue|
            existing_issue.assign_milestone(milestone)

            expect(existing_issue).to have_milestone(milestone.title)
          end
        end
      end

      shared_examples 'milestone assigned to new issue' do
        it 'is assigned to a new issue' do
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
        let(:milestone) do
          Resource::GroupMilestone.fabricate_via_api! do |milestone|
            milestone.group = group
            milestone.start_date = start_date
            milestone.due_date = due_date
          end
        end

        it_behaves_like 'milestone assigned to existing issue'
        it_behaves_like 'milestone assigned to new issue'
      end

      context 'Project milestone' do
        let(:milestone) do
          Resource::ProjectMilestone.fabricate_via_api! do |milestone|
            milestone.project = project
            milestone.start_date = start_date
            milestone.due_date = due_date
          end
        end

        it_behaves_like 'milestone assigned to existing issue'
        it_behaves_like 'milestone assigned to new issue'
      end
    end
  end
end

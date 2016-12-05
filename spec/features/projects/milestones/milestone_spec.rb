require 'spec_helper'

describe 'Milestones', feature: true do
  context 'milestone summary' do
    let(:project) { create(:empty_project, :public) }
    let(:milestone) { create(:milestone, project: project) }

    it 'shows the total weight when sum is greater than zero' do
      create(:issue, project: project, milestone: milestone, weight: 3)
      create(:issue, project: project,  milestone: milestone, weight: 1)

      visit_milestone_page

      within '.milestone-summary' do
        expect(page).to have_content 'Total weight: 4'
      end
    end

    it 'hides the total weight when sum is equal to zero' do
      create(:issue, project: project, milestone: milestone, weight: nil)
      create(:issue, project: project,  milestone: milestone, weight: nil)

      visit_milestone_page

      within '.milestone-summary' do
        expect(page).not_to have_content 'Total weight:'
      end
    end

    def visit_milestone_page
      visit namespace_project_milestone_path(project.namespace.to_param, project.to_param, milestone.to_param)
    end
  end
end

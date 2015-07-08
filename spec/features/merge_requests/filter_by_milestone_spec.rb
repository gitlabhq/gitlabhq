require 'rails_helper'

feature 'Merge Request filtering by Milestone', feature: true do
  include Select2Helper

  scenario 'filters by no Milestone', js: true do
    project = create(:project, :public)
    create(:merge_request, :with_diffs, source_project: project)

    visit_merge_requests(project)
    filter_by_milestone(Milestone::None.title)

    expect(page).to have_css('.merge-request-title', count: 1)
  end

  scenario 'filters by a specific Milestone', js: true do
    project = create(:project, :public)
    milestone = create(:milestone, project: project)
    create(:merge_request, :with_diffs, source_project: project, milestone: milestone)

    visit_merge_requests(project)
    filter_by_milestone(milestone.title)

    expect(page).to have_css('.merge-request-title', count: 1)
  end

  def visit_merge_requests(project)
    visit namespace_project_merge_requests_path(project.namespace, project)
  end

  def filter_by_milestone(title)
    select2(title, from: '#milestone_title')
  end
end

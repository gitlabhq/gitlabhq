require 'spec_helper'

feature 'Merge Request filtering by Milestone' do
  include Select2Helper

  let(:project) { create(:project) }

  before do
    login_as(:admin)
  end

  scenario 'User filters by Merge Requests without a Milestone', js: true do
    create(:merge_request, :simple, source_project: project)

    visit_merge_requests
    filter_by_milestone(Milestone::None.title)

    expect(page).to have_css('.merge-request-title', count: 1)
  end

  scenario 'User filters by Merge Requests with a specific Milestone', js: true do
    milestone = create(:milestone, project: project)
    create(:merge_request, :simple, source_project: project, milestone: milestone)

    visit_merge_requests
    filter_by_milestone(milestone.title)

    expect(page).to have_css('.merge-request-title', count: 1)
  end

  def visit_merge_requests
    visit namespace_project_merge_requests_path(project.namespace, project)
  end

  def filter_by_milestone(title)
    select2(title, from: '#milestone_title')
  end
end

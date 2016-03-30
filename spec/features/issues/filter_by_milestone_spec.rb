require 'rails_helper'

feature 'Issue filtering by Milestone', feature: true do
  let(:project)   { create(:project, :public) }
  let(:milestone) { create(:milestone, project: project) }

  scenario 'filters by no Milestone', js: true do
    create(:issue, project: project)
    create(:issue, project: project, milestone: milestone)

    visit_issues(project)
    filter_by_milestone(Milestone::None.title)

    expect(page).to have_css('.issue', count: 1)
  end

  context 'filters by upcoming milestone', js: true do
    it 'should not show issues with no expiry' do
      create(:issue, project: project)
      create(:issue, project: project, milestone: milestone)

      visit_issues(project)
      filter_by_milestone(Milestone::Upcoming.title)

      expect(page).to have_css('.issue', count: 0)
    end

    it 'should show issues in future' do
      milestone = create(:milestone, project: project, due_date: Date.tomorrow)
      create(:issue, project: project)
      create(:issue, project: project, milestone: milestone)

      visit_issues(project)
      filter_by_milestone(Milestone::Upcoming.title)

      expect(page).to have_css('.issue', count: 1)
    end

    it 'should not show issues in past' do
      milestone = create(:milestone, project: project, due_date: Date.yesterday)
      create(:issue, project: project)
      create(:issue, project: project, milestone: milestone)

      visit_issues(project)
      filter_by_milestone(Milestone::Upcoming.title)

      expect(page).to have_css('.issue', count: 0)
    end
  end

  scenario 'filters by a specific Milestone', js: true do
    create(:issue, project: project, milestone: milestone)
    create(:issue, project: project)

    visit_issues(project)
    filter_by_milestone(milestone.title)

    expect(page).to have_css('.issue', count: 1)
  end

  def visit_issues(project)
    visit namespace_project_issues_path(project.namespace, project)
  end

  def filter_by_milestone(title)
    find(".js-milestone-select").click
    find(".milestone-filter .dropdown-content a", text: title).click
  end
end

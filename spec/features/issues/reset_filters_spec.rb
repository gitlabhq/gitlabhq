require 'rails_helper'

feature 'Filter Resetter', feature: true do
  include WaitForAjax

  let(:project)    { create(:project, :public) }
  let(:milestone)  { create(:milestone, project: project) }

  context 'resets the milestone filter', js: true do
    it 'shows all issues when reset' do
      create(:issue, project: project, milestone: milestone)
      create(:issue, project: project)

      visit_issues(project)

      filter_by_milestone(milestone.title)
      expect(page).to have_css(".issue", count: 1)

      reset_filters
      expect(page).to have_css(".issue", count: 2)
    end
  end

  context 'resets labels filter', js:true do
    it 'shows all issues when reset' do
      bug = create(:label, project: project, title: 'bug')
      issue1 = create(:issue, title: "Bugfix1", project: project)
      issue1.labels << bug
      issue2 = create(:issue, title: "Feature", project: project)

      visit_issues(project)

      filter_by_label(bug.title)
      expect(page).to have_css(".issue", count: 1)

      reset_filters
      expect(page).to have_css(".issue", count: 2)
    end
  end

  context 'resets text filter', js:true do
    it 'shows all issues when reset' do
      issue1 = create(:issue, title: "Bugfix1", project: project)
      issue2 = create(:issue, title: "Feature", project: project)

      visit_issues(project)
      fill_in 'issue_search', with: 'Bug'
      expect(page).to have_css(".issue", count: 1)

      reset_filters
      expect(page).to have_css(".issue", count: 2)
    end
  end

  context 'resets label and text dually applied', js:true do
    it 'shows all issues when reset' do
      bug = create(:label, project: project, title: 'bug')
      issue1 = create(:issue, title: "Bugfix1", project: project)
      issue1.labels << bug
      issue2 = create(:issue, project: project, title: 'Feature1')

      visit_issues(project)
      expect(page).to have_css('.issue', count: 2)

      fill_in 'issue_search', with: 'Feat'
      expect(page).to have_css(".issue", count: 1)

      wait_for_ajax

      filter_by_label(bug.title)
      expect(page).to have_css(".issue", count: 0)

      reset_filters
      expect(page).to have_css(".issue", count: 2)
    end
  end

  def filter_by_milestone(title)
    find(".js-milestone-select").click
    find(".milestone-filter .dropdown-content a", text: title).click
  end

  def filter_by_label(title)
    find(".js-label-select").click
    find(".labels-filter .dropdown-content a", text: title).click
    find(".labels-filter .dropdown-title .dropdown-menu-close-icon").click
  end

  def reset_filters()
    find(".reset-filters").click
    wait_for_ajax
  end

  def visit_issues(project)
    visit namespace_project_issues_path(project.namespace, project)
  end
end

require 'rails_helper'

feature 'Issues filter reset button', feature: true, js: true do
  include WaitForAjax

  let!(:project)    { create(:project, :public) }
  let!(:user)        { create(:user)}
  let!(:milestone)  { create(:milestone, project: project) }
  let!(:bug)        { create(:label, project: project, name: 'bug')}
  let!(:issue1)     { create(:issue, project: project, milestone: milestone, author: user, assignee: user, title: 'Feature')}
  let!(:issue2)     { create(:labeled_issue, project: project, labels: [bug], title: 'Bugfix1')}

  before do
    project.team << [user, :developer]
    visit_issues(project)
  end

  context 'when a milestone filter has been applied' do
    it 'resets the milestone filter' do
      filter_by_milestone(milestone.title)
      expect(page).to have_css('.issue', count: 1)

      reset_filters
      expect(page).to have_css('.issue', count: 2)
    end
  end

  context 'when a label filter has been applied' do
    it 'resets the label filter' do
      filter_by_label(bug.title)
      expect(page).to have_css('.issue', count: 1)

      reset_filters
      expect(page).to have_css('.issue', count: 2)
    end
  end

  context 'when a text search has been conducted' do
    it 'resets the text search filter' do

      fill_in 'issue_search', with: 'Bug'
      expect(page).to have_css('.issue', count: 1)

      reset_filters
      expect(page).to have_css('.issue', count: 2)
    end
  end

  context 'when author filter has been applied' do
    it 'resets the author filter' do
      filter_by_author(user.name)
      expect(page).to have_css('.issue', count: 1)

      reset_filters
      expect(page).to have_css('.issue', count: 2)
    end
  end

  context 'when assignee filter has been applied' do
    it 'resets the assignee filter' do
      filter_by_assignee(user.name)
      expect(page).to have_css('.issue', count: 1)

      reset_filters
      expect(page).to have_css('.issue', count: 2)
    end
  end

  context 'when all filters have been applied' do
    it 'resets all filters' do

      wait_for_ajax

      filter_by_milestone(milestone.title)

      wait_for_ajax

      filter_by_author(user.username)

      wait_for_ajax

      expect(page).to have_css('.issue', count: 0)

      reset_filters
      expect(page).to have_css('.issue', count: 2)
    end
  end

  def filter_by_milestone(title)
    find('.js-milestone-select').click
    find('.milestone-filter .dropdown-content a', text: title).click
  end

  def filter_by_label(title)
    find('.js-label-select').click
    find('.labels-filter .dropdown-content a', text: title).click
    find('.labels-filter .dropdown-title .dropdown-menu-close-icon').click
  end

  def filter_by_author(name)
    find('.js-author-search').click
    find('.dropdown-menu-author .dropdown-content a', text: name).click
  end

  def filter_by_assignee(name)
    find('.js-assignee-search').click
    find('.dropdown-menu-assignee .dropdown-content a', text: name).click
  end

  def reset_filters
    find('.reset-filters').click
    wait_for_ajax
  end

  def visit_issues(project)
    visit namespace_project_issues_path(project.namespace, project)
  end
end

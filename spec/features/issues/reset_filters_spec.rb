require 'rails_helper'

feature 'Issues filter reset button', feature: true, js: true do
  include WaitForAjax
  include IssueHelpers

  let!(:project)    { create(:project, :public) }
  let!(:user)        { create(:user)}
  let!(:milestone)  { create(:milestone, project: project) }
  let!(:bug)        { create(:label, project: project, name: 'bug')}
  let!(:issue1)     { create(:issue, project: project, milestone: milestone, author: user, assignee: user, title: 'Feature')}
  let!(:issue2)     { create(:labeled_issue, project: project, labels: [bug], title: 'Bugfix1')}

  before do
    project.team << [user, :developer]
  end

  context 'when a milestone filter has been applied' do
    it 'resets the milestone filter' do
      visit_issues(project, milestone_title: milestone.title)
      expect(page).to have_css('.issue', count: 1)

      reset_filters
      expect(page).to have_css('.issue', count: 2)
    end
  end

  context 'when a label filter has been applied' do
    it 'resets the label filter' do
      visit_issues(project, label_name: bug.name)
      expect(page).to have_css('.issue', count: 1)

      reset_filters
      expect(page).to have_css('.issue', count: 2)
    end
  end

  context 'when a text search has been conducted' do
    it 'resets the text search filter' do
      visit_issues(project, search: 'Bug')
      expect(page).to have_css('.issue', count: 1)

      reset_filters
      expect(page).to have_css('.issue', count: 2)
    end
  end

  context 'when author filter has been applied' do
    it 'resets the author filter' do
      visit_issues(project, author_id: user.id)
      expect(page).to have_css('.issue', count: 1)

      reset_filters
      expect(page).to have_css('.issue', count: 2)
    end
  end

  context 'when assignee filter has been applied' do
    it 'resets the assignee filter' do
      visit_issues(project, assignee_id: user.id)
      expect(page).to have_css('.issue', count: 1)

      reset_filters
      expect(page).to have_css('.issue', count: 2)
    end
  end

  context 'when all filters have been applied' do
    it 'resets all filters' do
      visit_issues(project, assignee_id: user.id, author_id: user.id, milestone_title: milestone.title, label_name: bug.name, search: 'Bug')
      expect(page).to have_css('.issue', count: 0)

      reset_filters
      expect(page).to have_css('.issue', count: 2)
    end
  end

  def reset_filters
    find('.reset-filters').click
  end
end

require 'rails_helper'

feature 'Issues filter reset button', feature: true, js: true do
  include FilteredSearchHelpers
  include MergeRequestHelpers
  include WaitForAjax
  include IssueHelpers

  let!(:project) { create(:project, :public) }
  let!(:user) { create(:user) }
  let!(:milestone) { create(:milestone, project: project) }
  let!(:bug) { create(:label, project: project, name: 'bug')}
  let!(:mr1) { create(:merge_request, title: "Feature", source_project: project, target_project: project, source_branch: "Feature", milestone: milestone, author: user, assignee: user) }
  let!(:mr2) { create(:merge_request, title: "Bugfix1", source_project: project, target_project: project, source_branch: "Bugfix1") }

  let(:merge_request_css) { '.merge-request' }
  let(:clear_search_css) { '.filtered-search-input-container .clear-search' }

  before do
    mr2.labels << bug
    project.team << [user, :developer]
  end

  context 'when a milestone filter has been applied' do
    it 'resets the milestone filter' do
      visit_merge_requests(project, milestone_title: milestone.title)
      expect(page).to have_css(merge_request_css, count: 1)

      reset_filters
      expect(page).to have_css(merge_request_css, count: 2)
    end
  end

  context 'when a label filter has been applied' do
    it 'resets the label filter' do
      visit_merge_requests(project, label_name: bug.name)
      expect(page).to have_css(merge_request_css, count: 1)

      reset_filters
      expect(page).to have_css(merge_request_css, count: 2)
    end
  end

  context 'when a text search has been conducted' do
    it 'resets the text search filter' do
      visit_merge_requests(project, search: 'Bug')
      expect(page).to have_css(merge_request_css, count: 1)

      reset_filters
      expect(page).to have_css(merge_request_css, count: 2)
    end
  end

  context 'when author filter has been applied' do
    it 'resets the author filter' do
      visit_merge_requests(project, author_username: user.username)
      expect(page).to have_css(merge_request_css, count: 1)

      reset_filters
      expect(page).to have_css(merge_request_css, count: 2)
    end
  end

  context 'when assignee filter has been applied' do
    it 'resets the assignee filter' do
      visit_merge_requests(project, assignee_username: user.username)
      expect(page).to have_css(merge_request_css, count: 1)

      reset_filters
      expect(page).to have_css(merge_request_css, count: 2)
    end
  end

  context 'when all filters have been applied' do
    it 'resets all filters' do
      visit_merge_requests(project, assignee_username: user.username, author_username: user.username, milestone_title: milestone.title, label_name: bug.name, search: 'Bug')
      expect(page).to have_css(merge_request_css, count: 0)

      reset_filters
      expect(page).to have_css(merge_request_css, count: 2)
    end
  end

  context 'when no filters have been applied' do
    it 'the reset link should not be visible' do
      visit_merge_requests(project)
      expect(page).to have_css(merge_request_css, count: 2)
      expect(page).not_to have_css(clear_search_css)
    end
  end
end

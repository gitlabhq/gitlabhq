require 'rails_helper'

feature 'Merge requests filter clear button', :js do
  include FilteredSearchHelpers
  include MergeRequestHelpers
  include IssueHelpers

  let!(:project) { create(:project, :public, :repository) }
  let!(:user) { create(:user) }
  let!(:milestone) { create(:milestone, project: project) }
  let!(:bug) { create(:label, project: project, name: 'bug')}
  let!(:mr1) { create(:merge_request, title: "Feature", source_project: project, target_project: project, source_branch: "improve/awesome", milestone: milestone, author: user, assignee: user) }
  let!(:mr2) { create(:merge_request, title: "Bugfix1", source_project: project, target_project: project, source_branch: "fix") }

  let(:merge_request_css) { '.merge-request' }
  let(:clear_search_css) { '.filtered-search-box .clear-search' }

  before do
    mr2.labels << bug
    project.team << [user, :developer]
  end

  context 'when a milestone filter has been applied' do
    it 'resets the milestone filter' do
      visit_merge_requests(project, milestone_title: milestone.title)

      expect(page).to have_css(merge_request_css, count: 1)
      expect(get_filtered_search_placeholder).to eq('')

      reset_filters

      expect(page).to have_css(merge_request_css, count: 2)
      expect(get_filtered_search_placeholder).to eq(default_placeholder)
    end
  end

  context 'when a label filter has been applied' do
    it 'resets the label filter' do
      visit_merge_requests(project, label_name: bug.name)

      expect(page).to have_css(merge_request_css, count: 1)
      expect(get_filtered_search_placeholder).to eq('')

      reset_filters

      expect(page).to have_css(merge_request_css, count: 2)
      expect(get_filtered_search_placeholder).to eq(default_placeholder)
    end
  end

  context 'when multiple label filters have been applied' do
    let!(:label) { create(:label, project: project, name: 'Frontend') }
    let(:filter_dropdown) { find("#js-dropdown-label .filter-dropdown") }

    before do
      visit_merge_requests(project)
      init_label_search
    end

    it 'filters bug label' do
      filtered_search.set('~bug')

      filter_dropdown.find('.filter-dropdown-item', text: bug.title).click
      init_label_search

      expect(filter_dropdown.find('.filter-dropdown-item', text: bug.title)).to be_visible
      expect(filter_dropdown.find('.filter-dropdown-item', text: label.title)).to be_visible
    end
  end

  context 'when a text search has been conducted' do
    it 'resets the text search filter' do
      visit_merge_requests(project, search: 'Bug')

      expect(page).to have_css(merge_request_css, count: 1)
      expect(get_filtered_search_placeholder).to eq('')

      reset_filters

      expect(page).to have_css(merge_request_css, count: 2)
      expect(get_filtered_search_placeholder).to eq(default_placeholder)
    end
  end

  context 'when author filter has been applied' do
    it 'resets the author filter' do
      visit_merge_requests(project, author_username: user.username)

      expect(page).to have_css(merge_request_css, count: 1)
      expect(get_filtered_search_placeholder).to eq('')

      reset_filters

      expect(page).to have_css(merge_request_css, count: 2)
      expect(get_filtered_search_placeholder).to eq(default_placeholder)
    end
  end

  context 'when assignee filter has been applied' do
    it 'resets the assignee filter' do
      visit_merge_requests(project, assignee_username: user.username)

      expect(page).to have_css(merge_request_css, count: 1)
      expect(get_filtered_search_placeholder).to eq('')

      reset_filters

      expect(page).to have_css(merge_request_css, count: 2)
      expect(get_filtered_search_placeholder).to eq(default_placeholder)
    end
  end

  context 'when all filters have been applied' do
    it 'clears all filters' do
      visit_merge_requests(project, assignee_username: user.username, author_username: user.username, milestone_title: milestone.title, label_name: bug.name, search: 'Bug')

      expect(page).to have_css(merge_request_css, count: 0)
      expect(get_filtered_search_placeholder).to eq('')

      reset_filters

      expect(page).to have_css(merge_request_css, count: 2)
      expect(get_filtered_search_placeholder).to eq(default_placeholder)
    end
  end

  context 'when no filters have been applied' do
    it 'the clear button should not be visible' do
      visit_merge_requests(project)

      expect(page).to have_css(merge_request_css, count: 2)
      expect(get_filtered_search_placeholder).to eq(default_placeholder)
      expect(page).not_to have_css(clear_search_css)
    end
  end
end

# frozen_string_literal: true

# covered by ./accessibility_spec.rb

require 'spec_helper'

RSpec.describe 'Dashboard > User filters todos', :js, feature_category: :notifications do
  let(:user_1)    { create(:user, username: 'user_1', name: 'user_1') }
  let(:user_2)    { create(:user, username: 'user_2', name: 'user_2') }

  let(:group1) { create(:group) }
  let(:group2) { create(:group) }

  let(:project_1) { create(:project, name: 'project_1', namespace: group1) }
  let(:project_2) { create(:project, name: 'project_2', namespace: group1) }
  let(:project_3) { create(:project, name: 'project_3', namespace: group2) }

  let(:issue1) { create(:issue, title: 'issue', project: project_1) }
  let(:issue2) { create(:issue, title: 'issue', project: project_3) }

  let!(:merge_request) { create(:merge_request, source_project: project_2, title: 'merge_request') }

  before do
    create(:todo, user: user_1, author: user_2, project: project_1, target: issue1, action: 1)
    create(:todo, user: user_1, author: user_2, project: project_3, target: issue2, action: 1)
    create(:todo, user: user_1, author: user_1, project: project_2, target: merge_request, action: 2)

    project_1.add_developer(user_1)
    project_2.add_developer(user_1)
    project_3.add_developer(user_1)
    sign_in(user_1)
    visit dashboard_todos_path
  end

  it 'displays all todos without a filter' do
    expect(page).to have_content issue1.to_reference(full: false)
    expect(page).to have_content merge_request.to_reference(full: false)
    expect(page).to have_content issue2.to_reference(full: false)
  end

  it 'filters by project' do
    set_filter('Project', project_1.full_path)

    expect(page).to     have_content project_1.full_name
    expect(page).not_to have_content project_2.full_name
  end

  context 'Author filter' do
    it 'filters by author' do
      set_filter('Author', user_1.name)

      expect(find_by_testid('todo-item-list-container')).to     have_content '!'
      expect(find_by_testid('todo-item-list-container')).not_to have_content '#'
    end

    it 'shows only authors of existing todos' do
      create :user # should not show

      expect_filter_values('Author', [user_1.name, user_2.name])
    end

    it 'shows only authors of existing done todos' do
      user_3 = create :user
      user_4 = create :user
      create(:todo, user: user_1, author: user_3, project: project_1, target: issue1, action: 1, state: :done)
      create(:todo, user: user_1, author: user_4, project: project_2, target: merge_request, action: 2, state: :done)

      visit dashboard_todos_path(state: 'done')

      expect_filter_values('Author', [user_3.name, user_4.name])
    end
  end

  it 'filters by category' do
    set_filter('Category', 'Issue')

    expect(find_by_testid('todo-item-list-container')).to     have_content issue1.to_reference
    expect(find_by_testid('todo-item-list-container')).to     have_content issue2.to_reference
    expect(find_by_testid('todo-item-list-container')).not_to have_content merge_request.to_reference
  end

  describe 'filter by action' do
    before do
      create(:todo, :build_failed, user: user_1, author: user_2, project: project_2, target: merge_request)
      create(:todo, :marked, user: user_1, author: user_2, project: project_1, target: issue1)
      create(:todo, :review_requested, user: user_1, author: user_2, project: project_2, target: merge_request)
    end

    it 'filters by Assigned' do
      set_filter('Reason', 'Assigned')

      expect_to_see_action(:assigned)
    end

    it 'filters by Review Requested' do
      set_filter('Reason', 'Review requested')

      expect_to_see_action(:review_requested)
    end

    it 'filters by Mentioned' do
      set_filter('Reason', 'Mentioned')

      expect_to_see_action(:mentioned)
    end

    it 'filters by Added' do
      set_filter('Reason', 'Marked')

      expect_to_see_action(:marked)
    end

    it 'filters by Pipelines' do
      set_filter('Reason', 'Build failed')

      expect_to_see_action(:build_failed)
    end

    def expect_to_see_action(action_name)
      action_names = {
        assigned: ' assigned you',
        review_requested: ' requested a review',
        mentioned: ' mentioned',
        marked: ' added a to-do item',
        build_failed: ' pipeline failed'
      }

      action_name_text = action_names.delete(action_name)
      expect(find_by_testid('todo-item-list-container')).to have_content action_name_text
      action_names.each_value do |other_action_text|
        expect(find_by_testid('todo-item-list-container')).not_to have_content other_action_text
      end
    end
  end

  describe 'todos tab count' do
    context 'when filtering by open todos' do
      it 'includes all open todos' do
        expect(find_by_testid('pending-todos-count')).to have_content('3')
      end

      it 'only counts open todos that match when filtered by project' do
        set_filter('Project', project_1.full_path)
        expect(find_by_testid('pending-todos-count')).to have_content('1')
      end
    end
  end

  def set_filter(filter, value)
    within_testid 'todos-filtered-search-container' do
      find_by_testid('filtered-search-term').click
      find('li', text: filter).click
      find('li', text: value).click
      find_by_testid('search-button').click
    end

    wait_for_requests
  end

  def expect_filter_values(filter, expected_values)
    find_by_testid('filtered-search-term').click
    find('li', text: filter).click

    within '.gl-filtered-search-suggestion-list' do
      expected_values.each do |value|
        expect(page).to have_css('.gl-filtered-search-suggestion', text: value)
      end

      # Make sure no other suggestions are shown
      expect(page).to have_css('.gl-filtered-search-suggestion', count: expected_values.count)
    end
  end
end

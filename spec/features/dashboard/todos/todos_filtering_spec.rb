# frozen_string_literal: true

# covered by ./accessibility_spec.rb

require 'spec_helper'

RSpec.describe 'Dashboard > User filters todos', :js, feature_category: :team_planning do
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
    click_button 'Project'
    within '.dropdown-menu-project' do
      fill_in 'Search projects', with: project_1.full_name
      click_link project_1.full_name
    end

    wait_for_requests

    expect(page).to     have_content project_1.full_name
    expect(page).not_to have_content project_2.full_name
  end

  it 'filters by group' do
    click_button 'Group'
    within '.dropdown-menu-group' do
      fill_in 'Search groups', with: group1.full_name
      click_link group1.full_name
    end

    wait_for_requests

    expect(page).to     have_content "issue · #{group1.name} / project_1 #{issue1.to_reference}"
    expect(page).to     have_content merge_request.to_reference.to_s
    expect(page).not_to have_content "issue · #{group2.name} / project_3 #{issue2.to_reference}"
  end

  context 'Author filter' do
    it 'filters by author' do
      click_button 'Author'

      within '.dropdown-menu-author' do
        fill_in 'Search authors', with: user_1.name
        click_link user_1.name
      end

      wait_for_requests

      expect(find('.todos-list')).to     have_content '!'
      expect(find('.todos-list')).not_to have_content '#'
    end

    it 'shows only authors of existing todos' do
      click_button 'Author'

      within '.dropdown-menu-author' do
        # It should contain two users + 'Any Author'
        expect(page).to have_selector('.dropdown-menu-user-link', count: 3)
        expect(page).to have_content(user_1.name)
        expect(page).to have_content(user_2.name)
      end
    end

    it 'shows only authors of existing done todos' do
      user_3 = create :user
      user_4 = create :user
      create(:todo, user: user_1, author: user_3, project: project_1, target: issue1, action: 1, state: :done)
      create(:todo, user: user_1, author: user_4, project: project_2, target: merge_request, action: 2, state: :done)

      project_1.add_developer(user_3)
      project_2.add_developer(user_4)

      visit dashboard_todos_path(state: 'done')

      click_button 'Author'

      within '.dropdown-menu-author' do
        # It should contain two users + 'Any Author'
        expect(page).to have_selector('.dropdown-menu-user-link', count: 3)
        expect(page).to have_content(user_3.name)
        expect(page).to have_content(user_4.name)
        expect(page).not_to have_content(user_1.name)
        expect(page).not_to have_content(user_2.name)
      end
    end
  end

  it 'filters by type' do
    click_button 'Type'
    within '.dropdown-menu-type' do
      click_link 'Issue'
    end

    wait_for_requests

    expect(find('.todos-list')).to     have_content issue1.to_reference
    expect(find('.todos-list')).to     have_content issue2.to_reference
    expect(find('.todos-list')).not_to have_content merge_request.to_reference
  end

  describe 'filter by action' do
    before do
      create(:todo, :build_failed, user: user_1, author: user_2, project: project_2, target: merge_request)
      create(:todo, :marked, user: user_1, author: user_2, project: project_1, target: issue1)
      create(:todo, :review_requested, user: user_1, author: user_2, project: project_2, target: merge_request)
    end

    it 'filters by Assigned' do
      filter_action('Assigned')

      expect_to_see_action(:assigned)
    end

    it 'filters by Review Requested' do
      filter_action('Review requested')

      expect_to_see_action(:review_requested)
    end

    it 'filters by Mentioned' do
      filter_action('Mentioned')

      expect_to_see_action(:mentioned)
    end

    it 'filters by Added' do
      filter_action('Added')

      expect_to_see_action(:marked)
    end

    it 'filters by Pipelines' do
      filter_action('Pipelines')

      expect_to_see_action(:build_failed)
    end

    def filter_action(name)
      click_button 'Action'
      within '.dropdown-menu-action' do
        click_link name
      end

      wait_for_requests
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
      expect(find('.todos-list')).to have_content action_name_text
      action_names.each_value do |other_action_text|
        expect(find('.todos-list')).not_to have_content other_action_text
      end
    end
  end

  describe 'todos tab count' do
    context 'when filtering by open todos' do
      it 'includes all open todos' do
        expect(find('.js-todos-pending .gl-badge')).to have_content('3')
      end

      it 'only counts open todos that match when filtered by project' do
        click_button 'Project'

        within '.dropdown-menu-project' do
          fill_in 'Search projects', with: project_1.full_name
          click_link project_1.full_name
        end

        expect(find('.js-todos-pending .gl-badge')).to have_content('1')
      end
    end

    context 'when filtering by done todos' do
      before do
        create(:todo, user: user_1, author: user_2, project: project_1, target: issue1, action: 1, state: :done)
        create(:todo, user: user_1, author: user_1, project: project_2, target: merge_request, action: 2, state: :done)

        visit dashboard_todos_path(state: 'done')
      end

      it 'includes all done todos' do
        expect(find('.js-todos-done .gl-badge')).to have_content('2')
      end

      it 'only counts done todos that match when filtered by project' do
        click_button 'Project'

        within '.dropdown-menu-project' do
          fill_in 'Search projects', with: project_1.full_name
          click_link project_1.full_name
        end

        expect(find('.js-todos-done .gl-badge')).to have_content('1')
      end
    end
  end
end

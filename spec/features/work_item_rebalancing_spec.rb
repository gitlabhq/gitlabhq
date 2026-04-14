# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Work item rebalancing', feature_category: :team_planning do
  include Features::SortingHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:user) { create(:user) }

  let(:alert_message_regex) { /Issues are being rebalanced at the moment/ }

  before_all do
    create(:issue, project: project)

    group.add_developer(user)
  end

  context 'when issue rebalancing is in progress' do
    before do
      create(:callout, user: user, feature_name: :work_items_onboarding_modal)
      sign_in(user)

      stub_feature_flags(block_issue_repositioning: true)
    end

    it 'shows an alert in project boards' do
      board = create(:board, project: project)

      visit project_board_path(project, board)

      expect(page).to have_selector('.gl-alert-info', text: alert_message_regex, count: 1)
    end

    it 'shows an alert in group boards' do
      board = create(:board, group: group)

      visit group_board_path(group, board)

      expect(page).to have_selector('.gl-alert-info', text: alert_message_regex, count: 1)
    end

    it 'shows an alert in project work items list with manual sort', :js do
      visit project_work_items_path(project, sort: 'relative_position')

      expect(page).to have_selector('.gl-alert-info',
        text: 'Sort order rebalancing in progress. Reordering is temporarily disabled.', count: 1)
    end

    it 'shows an alert in group work items list with manual sort', :js do
      visit group_work_items_path(group, sort: 'relative_position')

      expect(page).to have_selector('.gl-alert-info',
        text: 'Sort order rebalancing in progress. Reordering is temporarily disabled.', count: 1)
    end

    it 'does not show an alert in project work items list with other sorts' do
      visit project_work_items_path(project, sort: 'created_date')

      expect(page).not_to have_selector('.gl-alert-info',
        text: 'Sort order rebalancing in progress. Reordering is temporarily disabled.')
    end

    it 'does not show an alert in group work items list with other sorts' do
      visit group_work_items_path(group, sort: 'created_date')

      expect(page).not_to have_selector('.gl-alert-info',
        text: 'Sort order rebalancing in progress. Reordering is temporarily disabled.')
    end

    it 'shows alert when trying to switch to manual sort via dropdown in project work items list', :js do
      visit project_work_items_path(project)

      pajamas_sort_by 'Manual', from: 'Created date'

      wait_for_requests

      expect(page).to have_selector('.gl-alert-info',
        text: 'Sort order rebalancing in progress. Reordering is temporarily disabled.')
    end

    it 'shows alert when trying to switch to manual sort via dropdown in group work items list', :js do
      visit group_work_items_path(group)

      pajamas_sort_by 'Manual', from: 'Created date'

      wait_for_requests

      expect(page).to have_selector('.gl-alert-info',
        text: 'Sort order rebalancing in progress. Reordering is temporarily disabled.')
    end

    it 'does not show alert when switching to non-manual sort via dropdown in project work items list', :js do
      visit project_work_items_path(project)

      pajamas_sort_by 'Updated date', from: 'Created date'

      wait_for_requests

      expect(page).not_to have_selector('.gl-alert-info',
        text: 'Sort order rebalancing in progress. Reordering is temporarily disabled.')
    end

    it 'does not show alert when switching to non-manual sort via dropdown in group work items list', :js do
      visit group_work_items_path(group)

      pajamas_sort_by 'Updated date', from: 'Created date'

      wait_for_requests

      expect(page).not_to have_selector('.gl-alert-info',
        text: 'Sort order rebalancing in progress. Reordering is temporarily disabled.')
    end
  end
end

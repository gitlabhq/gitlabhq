# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User adds lists', :js, feature_category: :team_planning do
  let_it_be(:group) { create(:group, :nested) }
  let_it_be(:project) { create(:project, :public, namespace: group) }
  let_it_be(:group_board) { create(:board, group: group) }
  let_it_be(:project_board) { create(:board, project: project) }
  let_it_be(:user) { create(:user, maintainer_of: project, owner_of: group) }

  let_it_be(:milestone) { create(:milestone, project: project) }

  let_it_be(:group_label) { create(:group_label, group: group) }
  let_it_be(:project_label) { create(:label, project: project) }
  let_it_be(:backlog) { create(:group_label, group: group, name: 'Backlog') }
  let_it_be(:closed) { create(:group_label, group: group, name: 'Closed') }

  let_it_be(:issue) { create(:labeled_issue, project: project, labels: [group_label, project_label]) }

  where(:board_type) do
    [[:project], [:group]]
  end

  with_them do
    before do
      sign_in(user)

      case board_type
      when :project
        visit project_board_path(project, project_board)
      when :group
        visit group_board_path(group, group_board)
      end

      wait_for_all_requests
    end

    it 'creates new column for label containing labeled issue', :aggregate_failures do
      click_button 'New list'
      wait_for_all_requests

      select_label(group_label)

      expect(page).to have_selector('.board', text: group_label.title)
      expect(find('[data-testid="board-list"]:nth-child(2) .board-card')).to have_content(issue.title)
    end

    it 'creates new list for Backlog and closed labels' do
      click_button 'New list'
      wait_for_requests

      select_label(backlog)

      click_button 'New list'
      wait_for_requests

      select_label(closed)

      wait_for_requests

      expect(page).to have_selector('.board', text: closed.title)
      expect(find('[data-testid="board-list"]:nth-child(2) .board-header')).to have_content(backlog.title)
      expect(find('[data-testid="board-list"]:nth-child(3) .board-header')).to have_content(closed.title)
      expect(find('[data-testid="board-list"]:nth-child(4) .board-header')).to have_content('Closed')
    end
  end

  def select_label(label)
    click_button 'Select a label'

    find('label', text: label.title).click

    click_button 'Add to board'

    wait_for_all_requests
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project issue boards sidebar', :js, feature_category: :portfolio_management do
  include BoardHelpers

  let_it_be(:user)    { create(:user) }
  let_it_be(:group)   { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, namespace: group) }
  let_it_be(:board)   { create(:board, project: project) }
  let_it_be(:label)   { create(:label, project: project, name: 'Label') }
  let_it_be(:list)    { create(:list, board: board, label: label, position: 0) }

  let_it_be(:issue, reload: true) { create(:issue, project: project, relative_position: 1) }

  before do
    project.add_maintainer(user)
  end

  context 'when issues drawer is disabled' do
    before do
      stub_feature_flags(issues_list_drawer: false)
      sign_in(user)

      visit project_board_path(project, board)

      wait_for_requests
    end

    it_behaves_like 'issue boards sidebar'
  end

  context 'when issues drawer is enabled' do
    before do
      sign_in(user)

      visit project_board_path(project, board)

      wait_for_requests
    end

    it_behaves_like 'work item drawer'
  end

  def first_card
    find('[data-testid="board-list"]:nth-child(1)').first("[data-testid='board-card']")
  end

  def click_first_issue_card
    click_card(first_card)
  end

  def refresh_and_click_first_card
    page.refresh

    wait_for_requests

    first_card.click
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project issue boards sidebar', :js do
  include BoardHelpers

  let_it_be(:user)    { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:issue)   { create(:issue, project: project, relative_position: 1) }
  let_it_be(:board)   { create(:board, project: project) }
  let_it_be(:list)    { create(:list, board: board, position: 0) }
  let(:card)          { find('.board:nth-child(1)').first('.board-card') }

  before do
    project.add_maintainer(user)

    sign_in(user)

    visit project_board_path(project, board)
    wait_for_requests
  end

  it 'shows sidebar when clicking issue' do
    click_card(card)

    expect(page).to have_selector('.issue-boards-sidebar')
  end

  it 'closes sidebar when clicking issue' do
    click_card(card)

    expect(page).to have_selector('.issue-boards-sidebar')

    click_card(card)

    expect(page).not_to have_selector('.issue-boards-sidebar')
  end

  it 'closes sidebar when clicking close button' do
    click_card(card)

    expect(page).to have_selector('.issue-boards-sidebar')

    find("[data-testid='sidebar-drawer'] .gl-drawer-close-button").click

    expect(page).not_to have_selector('.issue-boards-sidebar')
  end

  it 'shows issue details when sidebar is open' do
    click_card(card)

    page.within('.issue-boards-sidebar') do
      expect(page).to have_content(issue.title)
      expect(page).to have_content(issue.to_reference)
    end
  end
end

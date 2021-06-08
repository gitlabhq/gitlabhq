# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project issue boards sidebar milestones', :js do
  include BoardHelpers

  let_it_be(:user)      { create(:user) }
  let_it_be(:project)   { create(:project, :public) }
  let_it_be(:milestone) { create(:milestone, project: project) }
  let_it_be(:issue1)    { create(:issue, project: project, relative_position: 1) }
  let_it_be(:issue2)    { create(:issue, project: project, milestone: milestone, relative_position: 2) }
  let_it_be(:board)     { create(:board, project: project) }
  let_it_be(:list)      { create(:list, board: board, position: 0) }

  let(:card1)           { find('.board:nth-child(1) .board-card:nth-of-type(1)') }
  let(:card2)           { find('.board:nth-child(1) .board-card:nth-of-type(2)') }

  before do
    project.add_maintainer(user)

    sign_in(user)

    visit project_board_path(project, board)
    wait_for_requests
  end

  context 'milestone' do
    it 'adds a milestone' do
      click_card(card1)

      page.within('[data-testid="sidebar-milestones"]') do
        click_button 'Edit'

        wait_for_requests

        click_button milestone.title

        wait_for_requests

        page.within('[data-testid="select-milestone"]') do
          expect(page).to have_content(milestone.title)
        end
      end
    end

    it 'removes a milestone' do
      click_card(card2)

      page.within('[data-testid="sidebar-milestones"]') do
        click_button 'Edit'

        wait_for_requests

        click_button "No milestone"

        wait_for_requests

        page.within('[data-testid="select-milestone"]') do
          expect(page).not_to have_content(milestone.title)
        end
      end
    end
  end
end

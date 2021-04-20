# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project issue boards sidebar due date', :js do
  include BoardHelpers

  let_it_be(:user)    { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:issue)   { create(:issue, project: project, relative_position: 1) }
  let_it_be(:board)   { create(:board, project: project) }
  let_it_be(:list)    { create(:list, board: board, position: 0) }

  let(:card)          { find('.board:nth-child(1)').first('.board-card') }

  around do |example|
    freeze_time { example.run }
  end

  before do
    project.add_maintainer(user)

    sign_in(user)

    visit project_board_path(project, board)
    wait_for_requests
  end

  context 'due date' do
    it 'updates due date' do
      click_card(card)

      page.within('[data-testid="sidebar-due-date"]') do
        today = Date.today.day

        click_button 'Edit'

        click_button today.to_s

        wait_for_requests

        expect(page).to have_content(today.to_s(:medium))
      end
    end
  end
end

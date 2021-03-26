# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project issue boards sidebar subscription', :js do
  include BoardHelpers

  let_it_be(:user)         { create(:user) }
  let_it_be(:project)      { create(:project, :public) }
  let_it_be(:issue1)       { create(:issue, project: project, relative_position: 1) }
  let_it_be(:issue2)       { create(:issue, project: project, relative_position: 2) }
  let_it_be(:subscription) { create(:subscription, user: user, project: project, subscribable: issue2, subscribed: true) }
  let_it_be(:board)        { create(:board, project: project) }
  let_it_be(:list)         { create(:list, board: board, position: 0) }
  let(:card1)              { find('.board:nth-child(1) .board-card:nth-of-type(1)') }
  let(:card2)              { find('.board:nth-child(1) .board-card:nth-of-type(2)') }

  before do
    stub_feature_flags(graphql_board_lists: false)

    project.add_maintainer(user)

    sign_in(user)

    visit project_board_path(project, board)
    wait_for_requests
  end

  context 'subscription' do
    it 'changes issue subscription' do
      click_card(card1)
      wait_for_requests

      page.within('.subscriptions') do
        find('[data-testid="subscription-toggle"] button:not(.is-checked)').click
        wait_for_requests

        expect(page).to have_css('[data-testid="subscription-toggle"] button.is-checked')
      end
    end

    it 'has checked subscription toggle when already subscribed' do
      click_card(card2)
      wait_for_requests

      page.within('.subscriptions') do
        find('[data-testid="subscription-toggle"] button.is-checked').click
        wait_for_requests

        expect(page).to have_css('[data-testid="subscription-toggle"] button:not(.is-checked)')
      end
    end
  end
end

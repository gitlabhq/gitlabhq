# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project issue boards sidebar assignee', :js,
  quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/332078',
  feature_category: :portfolio_management do
  include BoardHelpers

  let_it_be(:user)        { create(:user) }
  let_it_be(:project)     { create(:project, :public) }
  let_it_be(:development) { create(:label, project: project, name: 'Development') }
  let_it_be(:regression)  { create(:label, project: project, name: 'Regression') }
  let_it_be(:stretch)     { create(:label, project: project, name: 'Stretch') }

  let!(:issue1)           { create(:labeled_issue, project: project, assignees: [user], labels: [development], relative_position: 2) }
  let!(:issue2)           { create(:labeled_issue, project: project, labels: [development, stretch], relative_position: 1) }
  let(:board)             { create(:board, project: project) }
  let!(:list)             { create(:list, board: board, label: development, position: 0) }
  let(:card)              { find('[data-testid="board-list"]:nth-child(2)').first('.board-card') }

  before do
    stub_licensed_features(multiple_issue_assignees: false)

    project.add_maintainer(user)

    sign_in(user)

    visit project_board_path(project, board)
    wait_for_requests
  end

  context 'assignee' do
    let(:assignees_widget) { '[data-testid="issue-boards-sidebar"] [data-testid="assignees-widget"]' }

    it 'updates the issues assignee' do
      click_card(card)

      page.within(assignees_widget) do
        click_button('Edit')

        wait_for_requests

        assignee = first('.gl-avatar-labeled').find('.gl-avatar-labeled-label').text

        page.within('.dropdown-menu-user') do
          first('.gl-avatar-labeled').click
        end

        expect(page).to have_content(assignee)
      end

      wait_for_requests

      expect(card).to have_selector('.avatar')
    end

    it 'removes the assignee' do
      card_two = find('[data-testid="board-list"]:nth-child(2)').find('.board-card:nth-child(2)')
      click_card(card_two)

      page.within(assignees_widget) do
        click_button('Edit')

        wait_for_requests

        page.within('.dropdown-menu-user') do
          find_by_testid('unassign').click
        end

        expect(page).to have_content('None')
      end

      expect(card_two).not_to have_selector('.avatar')
    end

    it 'assignees to current user' do
      click_card(card)

      page.within(assignees_widget) do
        expect(page).to have_content('None')

        click_button 'assign yourself'

        wait_for_requests

        expect(page).to have_content(user.name)
      end

      expect(card).to have_selector('.avatar')
    end

    it 'updates assignee dropdown' do
      click_card(card)

      page.within(assignees_widget) do
        click_button('Edit')

        wait_for_requests

        assignee = first('.gl-avatar-labeled').find('.gl-avatar-labeled-label').text

        page.within('.dropdown-menu-user') do
          first('.gl-avatar-labeled').click
        end

        expect(page).to have_content(assignee)
      end

      page.within(find('[data-testid="board-list"]:nth-child(2)')) do
        find('.board-card:nth-child(2)').click
      end

      page.within(assignees_widget) do
        click_button('Edit')

        expect(find('.dropdown-menu')).to have_selector('.gl-dropdown-item-check-icon')
      end
    end
  end
end

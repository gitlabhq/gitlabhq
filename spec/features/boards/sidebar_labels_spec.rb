# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project issue boards sidebar labels', :js, feature_category: :portfolio_management do
  include BoardHelpers

  let_it_be(:group)       { create(:group, :public) }
  let_it_be(:user)        { create(:user) }
  let_it_be(:project)     { create(:project, :public, namespace: group) }
  let_it_be(:development) { create(:label, project: project, name: 'Development') }
  let_it_be(:bug)         { create(:label, project: project, name: 'Bug') }
  let_it_be(:regression)  { create(:label, project: project, name: 'Regression') }
  let_it_be(:stretch)     { create(:label, project: project, name: 'Stretch') }
  let_it_be(:issue1)      { create(:labeled_issue, project: project, labels: [development], relative_position: 2) }
  let_it_be(:issue2)      { create(:labeled_issue, project: project, labels: [development, stretch], relative_position: 1) }
  let_it_be(:issue3)      { create(:issue, project: project) }
  let_it_be(:board)       { create(:board, project: project) }
  let_it_be(:list1)       { create(:list, board: board, label: development, position: 0) }
  let_it_be(:list2)       { create(:list, board: board, label: bug, position: 1) }

  let(:backlog_list)      { find('[data-testid="board-list"]:nth-child(1)') }
  let(:development_list)  { find('[data-testid="board-list"]:nth-child(2)') }
  let(:bug_list)          { find('[data-testid="board-list"]:nth-child(3)') }
  let(:card)              { development_list.first('.board-card') }
  let(:backlog_card)      { backlog_list.first('.board-card') }

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

    it 'shows current labels when editing' do
      click_card(card)

      page.within('.labels') do
        click_button 'Edit'

        wait_for_requests

        page.within('.value') do
          expect(page).to have_selector('.gl-label-text', count: 2)
          expect(page).to have_content(development.title)
          expect(page).to have_content(stretch.title)
        end
      end
    end

    it 'adds a single label' do
      click_card(card)

      page.within('.labels') do
        click_button 'Edit'

        wait_for_requests

        click_on bug.title

        click_button 'Close'

        wait_for_requests

        page.within('.value') do
          expect(page).to have_selector('.gl-label-text', count: 3)
          expect(page).to have_content(bug.title)
        end
      end

      click_button 'Close drawer'

      wait_for_requests

      # 'Development' label does not show since the card is in a 'Development' list label
      expect(card).to have_selector('.gl-label', count: 2)
      expect(card).to have_content(bug.title)

      # Card is duplicated in the 'Bug' list
      page.within(bug_list) do
        expect(page).to have_selector('.board-card', count: 1)
        expect(page).to have_content(issue2.title)
        expect(find('.board-card')).to have_content(development.title)
      end
    end

    it 'adds a multiple labels' do
      click_card(card)

      page.within('.labels') do
        click_button 'Edit'

        wait_for_requests

        click_on bug.title

        click_on regression.title

        click_button 'Close'

        wait_for_requests

        page.within('.value') do
          expect(page).to have_selector('.gl-label-text', count: 4)
          expect(page).to have_content(bug.title)
          expect(page).to have_content(regression.title)
        end
      end

      # 'Development' label does not show since the card is in a 'Development' list label
      expect(card).to have_selector('.gl-label', count: 3)
      expect(card).to have_content(bug.title)
      expect(card).to have_content(regression.title)
    end

    it 'removes a label and moves card to backlog' do
      click_card(card)

      page.within('.labels') do
        click_button 'Edit'

        wait_for_requests

        click_button development.title

        click_button 'Close'

        wait_for_requests
      end

      click_button 'Close drawer'

      wait_for_requests

      # Card is moved to the 'Backlog' list
      page.within(backlog_list) do
        expect(page).to have_selector('.board-card', count: 2)
        expect(page).to have_content(issue2.title)
      end

      # Card is moved away from the 'Development' list
      page.within(development_list) do
        expect(page).to have_selector('.board-card', count: 1)
        expect(page).not_to have_content(issue2.title)
      end
    end

    it 'adds a label to backlog card and moves the card to the list' do
      click_card(backlog_card)

      page.within('.labels') do
        click_button 'Edit'

        wait_for_requests

        click_on development.title

        click_button 'Close'

        wait_for_requests
      end

      click_button 'Close drawer'

      wait_for_requests

      # Card is removed from backlog
      page.within(backlog_list) do
        expect(page).to have_selector('.board-card', count: 0)
      end

      # Card is shown in the 'Development' list
      page.within(development_list) do
        expect(page).to have_selector('.board-card', count: 3)
        expect(page).to have_content(issue3.title)
      end
    end

    it 'removes a label' do
      click_card(card)

      page.within('.labels') do
        click_button 'Edit'

        wait_for_requests

        click_button stretch.title

        click_button 'Close'

        wait_for_requests

        page.within('.value') do
          expect(page).to have_selector('.gl-label-text', count: 1)
          expect(page).not_to have_content(stretch.title)
        end
      end

      # 'Development' label does not show since the card is in a 'Development' list label
      expect(card).to have_selector('.gl-label-text', count: 0)
      expect(card).not_to have_content(stretch.title)
    end

    it 'creates project label' do
      click_card(card)

      page.within('.labels') do
        click_button 'Edit'
        wait_for_requests

        click_on 'Create project label'
        fill_in 'Label name', with: 'test label'
        first('.suggested-colors a').click
        click_button 'Create'
        wait_for_requests

        expect(page).to have_button 'test label'
      end
      expect(page).to have_selector('.board', count: 4)
    end
  end

  context 'when issues drawer is enabled' do
    let(:labels_widget) { find_by_testid('work-item-labels') }

    before do
      sign_in(user)

      visit project_board_path(project, board)
      wait_for_requests
    end

    it 'shows current labels when editing' do
      click_card(card)

      page.within(labels_widget) do
        click_button 'Edit'

        wait_for_requests

        expect(page).to have_selector('.gl-new-dropdown-item-check-icon', count: 2)
        expect(page).to have_content(development.title)
        expect(page).to have_content(stretch.title)
      end
    end

    it 'adds a single label' do
      click_card(card)

      page.within(labels_widget) do
        click_button 'Edit'

        wait_for_requests

        find_label(bug.title).click
        click_button 'Apply'

        wait_for_requests

        expect(page).to have_selector('.gl-label-text', count: 3)
        expect(page).to have_content(bug.title)
      end

      find_by_testid('close-icon').click

      wait_for_requests

      # 'Development' label does not show since the card is in a 'Development' list label
      expect(card).to have_selector('.gl-label', count: 2)
      expect(card).to have_content(bug.title)

      # Card is duplicated in the 'Bug' list
      page.within(bug_list) do
        expect(page).to have_selector('.board-card', count: 1)
        expect(page).to have_content(issue2.title)
        expect(find('.board-card')).to have_content(development.title)
      end
    end

    it 'adds a multiple labels' do
      click_card(card)

      page.within(labels_widget) do
        click_button 'Edit'

        wait_for_requests

        find_label(bug.title).click
        find_label(regression.title).click

        click_button 'Apply'

        wait_for_requests

        expect(page).to have_selector('.gl-label-text', count: 4)
        expect(page).to have_content(bug.title)
        expect(page).to have_content(regression.title)
      end

      # 'Development' label does not show since the card is in a 'Development' list label
      expect(card).to have_selector('.gl-label', count: 3)
      expect(card).to have_content(bug.title)
      expect(card).to have_content(regression.title)
    end

    it 'removes a label and moves card to backlog' do
      click_card(card)

      page.within(labels_widget) do
        click_button 'Edit'

        wait_for_requests

        find_label(development.title).click

        click_button 'Apply'

        wait_for_requests
      end

      find_by_testid('close-icon').click

      wait_for_requests

      # Card is moved to the 'Backlog' list
      page.within(backlog_list) do
        expect(page).to have_selector('.board-card', count: 2)
        expect(page).to have_content(issue2.title)
      end

      # Card is moved away from the 'Development' list
      page.within(development_list) do
        expect(page).to have_selector('.board-card', count: 1)
        expect(page).not_to have_content(issue2.title)
      end
    end

    it 'adds a label to backlog card and moves the card to the list' do
      click_card(backlog_card)

      page.within(labels_widget) do
        click_button 'Edit'

        wait_for_requests

        find_label(development.title).click

        click_button 'Apply'

        wait_for_requests
      end

      find_by_testid('close-icon').click

      wait_for_requests

      # Card is removed from backlog
      page.within(backlog_list) do
        expect(page).to have_selector('.board-card', count: 0)
      end

      # Card is shown in the 'Development' list
      page.within(development_list) do
        expect(page).to have_selector('.board-card', count: 3)
        expect(page).to have_content(issue3.title)
      end
    end

    it 'removes a label' do
      click_card(card)

      page.within(labels_widget) do
        click_button 'Edit'

        wait_for_requests

        find_label(stretch.title).click

        click_button 'Apply'

        wait_for_requests

        expect(page).to have_selector('.gl-label-text', count: 1)
        expect(page).not_to have_content(stretch.title)
      end

      # 'Development' label does not show since the card is in a 'Development' list label
      expect(card).to have_selector('.gl-label-text', count: 0)
      expect(card).not_to have_content(stretch.title)
    end

    it 'creates project label' do
      click_card(card)

      page.within(labels_widget) do
        click_button 'Edit'
        wait_for_requests

        click_on 'Create project label'
        fill_in 'Label name', with: 'test label'
        first('.suggested-colors a').click
        click_button 'Create'
        wait_for_requests

        expect(page).to have_content('test label')
      end
      expect(page).to have_selector('.board', count: 4)
    end
  end

  def find_label(title)
    find('li', text: title, match: :prefer_exact)
  end
end

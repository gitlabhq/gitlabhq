# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project issue boards sidebar labels', :js, feature_category: :team_planning do
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
  let_it_be(:board)       { create(:board, project: project) }
  let_it_be(:list)        { create(:list, board: board, label: development, position: 0) }

  let(:card)              { find('.board:nth-child(2)').first('.board-card') }

  before do
    project.add_maintainer(user)

    sign_in(user)

    visit project_board_path(project, board)
    wait_for_requests
  end

  context 'labels' do
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

      # 'Development' label does not show since the card is in a 'Development' list label
      expect(card).to have_selector('.gl-label', count: 2)
      expect(card).to have_content(bug.title)
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
        fill_in 'Name new label', with: 'test label'
        first('.suggested-colors a').click
        click_button 'Create'
        wait_for_requests

        expect(page).to have_button 'test label'
      end
      expect(page).to have_selector('.board', count: 3)
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group Issue Boards', :js, feature_category: :portfolio_management do
  include BoardHelpers

  let(:group)            { create(:group) }
  let(:user)             { create(:group_member, user: create(:user), group: group).user }
  let!(:project_1)       { create(:project, :public, group: group) }
  let!(:project_2)       { create(:project, :public, group: group) }
  let!(:project_1_label) { create(:label, project: project_1, name: 'Development 1') }
  let!(:project_2_label) { create(:label, project: project_2, name: 'Development 2') }
  let!(:group_label)     { create(:group_label, title: 'Bug', description: 'Fusce consequat', group: group) }
  let!(:issue_1)         { create(:labeled_issue, project: project_1, relative_position: 1) }
  let!(:issue_2)         { create(:labeled_issue, project: project_2, relative_position: 2) }
  let(:board)            { create(:board, group: group) }
  let!(:list)            { create(:list, board: board, label: project_1_label, position: 0) }
  let(:card)             { find('[data-testid="board-list"]:nth-child(1)').first('.board-card') }

  context 'when work item drawer is disabled' do
    before do
      stub_feature_flags(issues_list_drawer: false)
      sign_in(user)

      visit group_board_path(group, board)
      wait_for_requests
    end

    context 'labels' do
      it 'only shows valid labels for the issue project and group' do
        click_card(card)

        page.within('.labels') do
          click_button 'Edit'

          wait_for_requests

          within_testid('dropdown-content') do
            expect(page).to have_content(project_1_label.title)
            expect(page).to have_content(group_label.title)
            expect(page).not_to have_content(project_2_label.title)
          end
        end
      end
    end
  end

  context 'when work item drawer is enabled' do
    before do
      sign_in(user)

      visit group_board_path(group, board)
      wait_for_requests
    end

    context 'labels' do
      it 'only shows valid labels for the issue project and group' do
        click_card(card)

        within_testid('work-item-labels') do
          click_button 'Edit'

          wait_for_requests

          expect(page).to have_content(project_1_label.title)
          expect(page).to have_content(group_label.title)
          expect(page).not_to have_content(project_2_label.title)
        end
      end
    end
  end
end

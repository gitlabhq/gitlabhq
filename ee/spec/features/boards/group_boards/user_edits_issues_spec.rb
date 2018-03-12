require 'spec_helper'

describe 'label issues', :js do
  include BoardHelpers

  let(:user) { create(:user) }
  let(:group) { create(:group, :public) }
  let(:project) { create(:project, :public, namespace: group) }
  let(:board) { create(:board, group: group) }
  let!(:development) { create(:label, project: project, name: 'Development') }
  let!(:issue) { create(:labeled_issue, project: project, labels: [development]) }
  let!(:list) { create(:list, board: board, label: development, position: 0) }

  before do
    stub_licensed_features(group_issue_boards: true)
    group.add_master(user)

    sign_in(user)

    visit group_boards_path(group)
    wait_for_requests
  end

  it 'adds a new group label from sidebar' do
    card = find('.board:nth-child(2)').first('.card')
    click_card(card)

    page.within '.right-sidebar .labels' do
      click_link 'Edit'
      click_link 'Create group label'
      fill_in 'new_label_name', with: 'test label'
      first('.suggest-colors-dropdown a').click
      click_button 'Create'
      wait_for_requests
    end

    page.within '.labels' do
      expect(page).to have_link 'test label'
    end
  end
end

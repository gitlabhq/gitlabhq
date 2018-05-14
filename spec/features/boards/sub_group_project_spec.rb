require 'rails_helper'

describe 'Sub-group project issue boards', :js do
  let(:group) { create(:group) }
  let(:nested_group_1) { create(:group, parent: group) }
  let(:project) { create(:project, group: nested_group_1) }
  let(:board) { create(:board, project: project) }
  let(:label) { create(:label, project: project) }
  let(:user) { create(:user) }
  let!(:list1) { create(:list, board: board, label: label, position: 0) }
  let!(:issue) { create(:labeled_issue, project: project, labels: [label]) }

  before do
    project.add_master(user)

    sign_in(user)

    visit project_board_path(project, board)
    wait_for_requests
  end

  it 'creates new label from sidebar' do
    find('.card').click

    page.within '.labels' do
      click_link 'Edit'
      click_link 'Create project label'
    end

    page.within '.dropdown-new-label' do
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

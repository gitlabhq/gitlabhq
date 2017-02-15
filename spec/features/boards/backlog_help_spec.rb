require 'rails_helper'

describe 'Issue Boards', :feature, :js do
  include WaitForVueResource

  let(:project) { create(:empty_project, :public) }
  let(:board) { create(:board, project: project) }
  let(:user) { create(:user) }
  let!(:issue) { create(:issue, project: project) }
  let!(:planning) { create(:label, project: project, name: 'Planning') }
  let!(:list1) { create(:list, board: board, label: planning, position: 0) }

  before do
    project.team << [user, :master]

    login_as(user)

    visit namespace_project_board_path(project.namespace, project, board)
    wait_for_vue_resource
  end

  it 'shows backlog help box' do
    expect(page).to have_selector('.boards-backlog-help')
  end

  it 'closes backlog help box' do
    page.within '.boards-backlog-help' do
      find('.close').click
    end

    expect(page).not_to have_selector('.boards-backlog-help')
  end

  it 'closes backlog help box after adding issues' do
    page.within '.boards-backlog-help' do
      click_button 'Add issues'
    end

    page.within('.add-issues-modal') do
      find('.card').click

      click_button 'Add 1 issue'
    end

    expect(page).not_to have_selector('.boards-backlog-help')
  end
end

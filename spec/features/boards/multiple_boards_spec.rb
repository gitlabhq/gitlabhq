require 'rails_helper'

describe 'Multiple Issue Boards', feature: true, js: true do
  include WaitForAjax
  include WaitForVueResource

  let(:user)      { create(:user) }
  let(:project)   { create(:empty_project, :public) }
  let!(:board)    { create(:board, project: project) }
  let!(:board2)   { create(:board, project: project) }

  before do
    project.team << [user, :master]

    login_as(user)

    visit namespace_project_boards_path(project.namespace, project)
    wait_for_vue_resource
  end

  it 'shows current board name' do
    page.within('.boards-switcher') do
      expect(page).to have_content(board.name)
    end
  end

  it 'shows a list of boards' do
    click_button board.name

    page.within('.boards-title-holder .dropdown-menu') do
      expect(page).to have_content(board.name)
      expect(page).to have_content(board2.name)
    end
  end

  it 'switches current board' do
    click_button board.name

    page.within('.boards-title-holder .dropdown-menu') do
      click_link board2.name
    end

    wait_for_vue_resource

    page.within('.boards-switcher') do
      expect(page).to have_content(board2.name)
    end
  end

  it 'edits board name' do
    click_button board.name

    page.within('.boards-title-holder .dropdown-menu') do
      click_link 'Edit board name'

      fill_in 'board-new-name', with: 'Testing'

      click_button 'Save'
    end

    wait_for_vue_resource

    page.within('.boards-title-holder .dropdown-menu') do
      expect(page).to have_content('Testing')
    end
  end

  it 'deletes board' do
    click_button board.name

    wait_for_vue_resource

    page.within('.boards-title-holder .dropdown-menu') do
      click_link 'Delete board'

      page.within('.dropdown-title') do
        expect(page).to have_content('Delete board')
      end

      click_link 'Delete'
    end

    click_button board.name

    page.within('.boards-title-holder .dropdown-menu') do
      expect(page).not_to have_content(board.name)
      expect(page).to have_content(board2.name)
    end
  end
end

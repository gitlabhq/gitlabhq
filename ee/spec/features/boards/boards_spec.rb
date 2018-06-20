require 'spec_helper'

describe 'issue boards', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }
  let!(:board) { create(:board, project: project) }

  context 'issue board focus mode' do
    before do
      project.add_developer(user)
      login_as(user)
    end

    it 'shows the button when the feature is enabled' do
      stub_licensed_features(issue_board_focus_mode: true)

      visit_board_page

      expect(page).to have_link('Toggle focus mode')
    end

    it 'hides the button when the feature is enabled' do
      stub_licensed_features(issue_board_focus_mode: false)

      visit_board_page

      expect(page).not_to have_link('Toggle focus mode')
    end
  end

  context 'with group and reporter' do
    let(:group) { create(:group) }
    let(:project) { create(:project, :public, namespace: group) }

    before do
      project.add_master(user)
      group.add_reporter(user)
      login_as(user)
    end

    it 'can edit board name' do
      visit_board_page

      board_name = board.name
      new_board_name = board_name + '-Test'

      click_button 'Edit board'
      fill_in 'board-new-name', with: new_board_name
      click_button 'Save changes'

      expect(page).to have_content new_board_name
    end
  end

  context 'add list dropdown' do
    let(:group) { create(:group) }
    let(:project) { create(:project, :public, namespace: group) }

    before do
      project.add_master(user)
      group.add_reporter(user)
      login_as(user)
    end

    it 'shows tabbed dropdown with labels list and assignees list' do
      stub_licensed_features(board_assignee_lists: true)

      visit_board_page

      page.within('#js-add-list') do
        page.find('.js-new-board-list').click
        wait_for_requests
        expect(page).to have_css('.dropdown-menu.dropdown-menu-tabs')
        expect(page).to have_css('.js-tab-button-labels')
        expect(page).to have_css('.js-tab-button-assignees')
      end
    end

    it 'shows simple dropdown with only labels list' do
      stub_licensed_features(board_assignee_lists: false)

      visit_board_page

      page.within('#js-add-list') do
        page.find('.js-new-board-list').click
        wait_for_requests
        expect(page).to have_css('.dropdown-menu.js-tab-container-labels')
        expect(page).to have_content('Create lists from labels. Issues with that label appear in that list.')
        expect(page).not_to have_css('.js-tab-button-assignees')
      end
    end
  end

  def visit_board_page
    visit project_boards_path(project)
    wait_for_requests
  end
end

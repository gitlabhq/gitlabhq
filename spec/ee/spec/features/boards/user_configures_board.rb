require 'rails_helper'

describe 'issue board config', :js do
  let(:user) { create(:user) }
  let(:project) { create(:project, :public) }
  let!(:planning) { create(:label, project: project, name: 'Planning') }
  let!(:board) { create(:board, project: project) }

  before do
    stub_licensed_features(multiple_issue_boards: true)
  end

  context 'user with edit permissions' do
    before do
      project.team << [user, :master]

      login_as(user)

      visit project_boards_path(project)
      wait_for_requests
    end

    it 'edits board' do
      click_button 'Edit board'

      page.within('.popup-dialog') do
        fill_in 'board-new-name', with: 'Testing'

        click_button 'Save'
      end

      expect('.dropdown-menu-toggle', text: 'Testing').to exist
    end
  end

  context 'user without edit permissions' do
    before do
      visit project_boards_path(project)
      wait_for_requests
    end

    it 'shows board scope' do
      click_button 'View scope'

      page.within('.popup-dialog') do
        expect(page).not_to have_link('Edit')
        expect(page).not_to have_button('Edit')
        expect(page).not_to have_button('Save')
      end
    end
  end
end
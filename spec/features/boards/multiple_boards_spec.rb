require 'rails_helper'

describe 'Multiple Issue Boards', feature: true, js: true do
  let(:user)      { create(:user) }
  let(:project)   { create(:empty_project, :public) }
  let!(:planning) { create(:label, project: project, name: 'Planning') }
  let!(:board)    { create(:board, project: project) }
  let!(:board2)   { create(:board, project: project) }

  context 'with multiple issue boards enabled' do
    before do
      stub_licensed_features(multiple_issue_boards: true)
    end

    context 'authorized user' do
      before do
        project.team << [user, :master]

        login_as(user)

        visit project_boards_path(project)
        wait_for_requests
      end

      it 'shows current board name' do
        page.within('.boards-switcher') do
          expect(page).to have_content(board.name)
        end
      end

      it 'shows a list of boards' do
        click_button board.name

        page.within('.dropdown-menu') do
          expect(page).to have_content(board.name)
          expect(page).to have_content(board2.name)
        end
      end

      it 'switches current board' do
        click_button board.name

        page.within('.dropdown-menu') do
          click_link board2.name
        end

        wait_for_requests

        page.within('.boards-switcher') do
          expect(page).to have_content(board2.name)
        end
      end

      it 'creates new board' do
        click_button board.name

        page.within('.dropdown-menu') do
          click_link 'Create new board'

          fill_in 'board-new-name', with: 'This is a new board'

          click_button 'Create'
        end

        wait_for_requests

        expect(page).to have_button('This is a new board')
      end

      it 'edits board name' do
        click_button board.name

        page.within('.dropdown-menu') do
          click_link 'Edit board name'

          fill_in 'board-new-name', with: 'Testing'

          click_button 'Save'
        end

        wait_for_requests

        page.within('.dropdown-menu') do
          expect(page).to have_content('Testing')
        end
      end

      it 'deletes board' do
        click_button board.name

        wait_for_requests

        page.within('.dropdown-menu') do
          click_link 'Delete board'

          page.within('.dropdown-title') do
            expect(page).to have_content('Delete board')
          end

          click_link 'Delete'
        end

        click_button board2.name

        page.within('.dropdown-menu') do
          expect(page).not_to have_content(board.name)
          expect(page).to have_content(board2.name)
        end
      end

      it 'adds a list to the none default board' do
        click_button board.name

        page.within('.dropdown-menu') do
          click_link board2.name
        end

        wait_for_requests

        page.within('.boards-switcher') do
          expect(page).to have_content(board2.name)
        end

        click_button 'Add list'

        wait_for_requests

        page.within '.dropdown-menu-issues-board-new' do
          click_link planning.title
        end

        wait_for_requests

        expect(page).to have_selector('.board', count: 3)

        click_button board2.name

        page.within('.dropdown-menu') do
          click_link board.name
        end

        wait_for_requests

        expect(page).to have_selector('.board', count: 2)
      end
    end

    context 'unauthorized user' do
      before do
        visit project_boards_path(project)
        wait_for_requests
      end

      it 'does not show action links' do
        click_button board.name

        page.within('.dropdown-menu') do
          expect(page).not_to have_content('Create new board')
          expect(page).not_to have_content('Edit board name')
          expect(page).not_to have_content('Delete board')
        end
      end
    end
  end

  context 'with multiple issue boards disabled' do
    before do
      stub_licensed_features(multiple_issue_boards: false)
      project.team << [user, :master]

      login_as(user)
    end

    it 'hides the link to create a new board' do
      visit project_boards_path(project)
      wait_for_requests

      click_button board.name

      page.within('.dropdown-menu') do
        expect(page).to have_content('Edit board name')
        expect(page).not_to have_content('Create new board')
        expect(page).not_to have_content('Delete board')
      end
    end

    it 'shows a mention that boards are hidden when multiple boards are created' do
      create(:board, project: project)

      visit project_boards_path(project)
      wait_for_requests

      click_button board.name

      expect(page).to have_content('Some of your boards are hidden, activate a license to see them again.')
    end
  end
end

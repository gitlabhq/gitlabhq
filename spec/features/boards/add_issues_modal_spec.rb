require 'rails_helper'

describe 'Issue Boards add issue modal', :feature, :js do
  include WaitForAjax
  include WaitForVueResource

  let(:project) { create(:empty_project, :public) }
  let(:board) { create(:board, project: project) }
  let(:user) { create(:user) }
  let!(:planning) { create(:label, project: project, name: 'Planning') }
  let!(:label) { create(:label, project: project) }
  let!(:list1) { create(:list, board: board, label: planning, position: 0) }
  let!(:list2) { create(:list, board: board, label: label, position: 1) }
  let!(:issue) { create(:issue, project: project) }
  let!(:issue2) { create(:issue, project: project) }

  before do
    project.team << [user, :master]

    login_as(user)

    visit namespace_project_board_path(project.namespace, project, board)
    wait_for_vue_resource
  end

  context 'modal interaction' do
    it 'opens modal' do
      click_add_issues

      expect(page).to have_selector('.add-issues-modal')
    end

    it 'closes modal' do
      click_add_issues

      page.within('.add-issues-modal') do
        find('.close').click
      end

      expect(page).not_to have_selector('.add-issues-modal')
    end

    it 'closes modal if cancel button clicked' do
      click_add_issues

      page.within('.add-issues-modal') do
        click_button 'Cancel'
      end

      expect(page).not_to have_selector('.add-issues-modal')
    end

    it 'does not show tooltip on add issues button' do
      button = page.find('.issue-boards-search button', text: 'Add issues')

      expect(button[:title]).not_to eq("Please add a list to your board first")
    end
  end

  context 'issues list' do
    before do
      click_add_issues

      wait_for_vue_resource
    end

    it 'loads issues' do
      page.within('.add-issues-modal') do
        page.within('.nav-links') do
          expect(page).to have_content('2')
        end

        expect(page).to have_selector('.card', count: 2)
      end
    end

    it 'shows selected issues' do
      page.within('.add-issues-modal') do
        click_link 'Selected issues'

        expect(page).not_to have_selector('.card')
      end
    end

    context 'list dropdown' do
      it 'resets after deleting list' do
        page.within('.add-issues-modal') do
          expect(find('.add-issues-footer')).to have_button(planning.title)

          click_button 'Cancel'
        end

        first('.board-delete').click

        click_add_issues

        wait_for_vue_resource

        page.within('.add-issues-modal') do
          expect(find('.add-issues-footer')).not_to have_button(planning.title)
          expect(find('.add-issues-footer')).to have_button(label.title)
        end
      end
    end

    context 'search' do
      it 'returns issues' do
        page.within('.add-issues-modal') do
          find('.form-control').native.send_keys(issue.title)

          expect(page).to have_selector('.card', count: 1)
        end
      end

      it 'returns no issues' do
        page.within('.add-issues-modal') do
          find('.form-control').native.send_keys('testing search')

          expect(page).not_to have_selector('.card')
          expect(page).not_to have_content("You haven't added any issues to your project yet")
        end
      end
    end

    context 'selecing issues' do
      it 'selects single issue' do
        page.within('.add-issues-modal') do
          first('.card').click

          page.within('.nav-links') do
            expect(page).to have_content('Selected issues 1')
          end
        end
      end

      it 'changes button text' do
        page.within('.add-issues-modal') do
          first('.card').click

          expect(first('.add-issues-footer .btn')).to have_content('Add 1 issue')
        end
      end

      it 'changes button text with plural' do
        page.within('.add-issues-modal') do
          all('.card').each do |el|
            el.click
          end

          expect(first('.add-issues-footer .btn')).to have_content('Add 2 issues')
        end
      end

      it 'shows only selected issues on selected tab' do
        page.within('.add-issues-modal') do
          first('.card').click

          click_link 'Selected issues'

          expect(page).to have_selector('.card', count: 1)
        end
      end

      it 'selects all issues' do
        page.within('.add-issues-modal') do
          click_button 'Select all'

          expect(page).to have_selector('.is-active', count: 2)
        end
      end

      it 'deselects all issues' do
        page.within('.add-issues-modal') do
          click_button 'Select all'

          expect(page).to have_selector('.is-active', count: 2)

          click_button 'Deselect all'

          expect(page).not_to have_selector('.is-active')
        end
      end

      it 'selects all that arent already selected' do
        page.within('.add-issues-modal') do
          first('.card').click

          expect(page).to have_selector('.is-active', count: 1)

          click_button 'Select all'

          expect(page).to have_selector('.is-active', count: 2)
        end
      end

      it 'unselects from selected tab' do
        page.within('.add-issues-modal') do
          first('.card').click

          click_link 'Selected issues'

          first('.card').click

          expect(page).not_to have_selector('.is-active')
        end
      end
    end

    context 'adding issues' do
      it 'adds to board' do
        page.within('.add-issues-modal') do
          first('.card').click

          click_button 'Add 1 issue'
        end

        page.within(first('.board')) do
          expect(page).to have_selector('.card')
        end
      end

      it 'adds to second list' do
        page.within('.add-issues-modal') do
          first('.card').click

          click_button planning.title

          click_link label.title

          click_button 'Add 1 issue'
        end

        page.within(find('.board:nth-child(2)')) do
          expect(page).to have_selector('.card')
        end
      end
    end
  end

  def click_add_issues
    page.within('.issue-boards-search') do
      click_button('Add issues')
    end
  end
end

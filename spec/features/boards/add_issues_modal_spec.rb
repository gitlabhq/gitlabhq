# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issue Boards add issue modal', :js do
  let(:project) { create(:project, :public) }
  let(:board) { create(:board, project: project) }
  let(:user) { create(:user) }
  let!(:planning) { create(:label, project: project, name: 'Planning') }
  let!(:label) { create(:label, project: project) }
  let!(:list1) { create(:list, board: board, label: planning, position: 0) }
  let!(:list2) { create(:list, board: board, label: label, position: 1) }
  let!(:issue) { create(:issue, project: project, title: 'abc', description: 'def') }
  let!(:issue2) { create(:issue, project: project, title: 'hij', description: 'klm') }

  before do
    project.add_maintainer(user)

    sign_in(user)

    visit project_board_path(project, board)
    wait_for_requests
  end

  it 'resets filtered search state' do
    visit project_board_path(project, board, search: 'testing')

    wait_for_requests

    click_button('Add issues')

    page.within('.add-issues-modal') do
      expect(find('.form-control').value).to eq('')
      expect(page).to have_selector('.clear-search', visible: false)
      expect(find('.form-control')[:placeholder]).to eq('Search or filter results...')
    end
  end

  context 'modal interaction' do
    before do
      stub_feature_flags(add_issues_button: true)
    end

    it 'opens modal' do
      click_button('Add issues')

      expect(page).to have_selector('.add-issues-modal')
    end

    it 'closes modal' do
      click_button('Add issues')

      page.within('.add-issues-modal') do
        find('.close').click
      end

      expect(page).not_to have_selector('.add-issues-modal')
    end

    it 'closes modal if cancel button clicked' do
      click_button('Add issues')

      page.within('.add-issues-modal') do
        click_button 'Cancel'
      end

      expect(page).not_to have_selector('.add-issues-modal')
    end

    it 'does not show tooltip on add issues button' do
      button = page.find('.filter-dropdown-container button', text: 'Add issues')

      expect(button[:title]).not_to eq("Please add a list to your board first")
    end
  end

  context 'issues list' do
    before do
      stub_feature_flags(add_issues_button: true)
      click_button('Add issues')

      wait_for_requests
    end

    it 'loads issues' do
      page.within('.add-issues-modal') do
        page.within('.gl-tabs') do
          expect(page).to have_content('2')
        end

        expect(page).to have_selector('.board-card', count: 2)
      end
    end

    it 'shows selected issues tab and empty state message' do
      page.within('.add-issues-modal') do
        click_link 'Selected issues'

        expect(page).not_to have_selector('.board-card')
        expect(page).to have_content("Go back to Open issues and select some issues to add to your board.")
      end
    end

    context 'list dropdown' do
      it 'resets after deleting list' do
        page.within('.add-issues-modal') do
          expect(find('.add-issues-footer')).to have_button(planning.title)

          click_button 'Cancel'
        end

        page.within(find('.board:nth-child(2)')) do
          find('button[title="List settings"]').click
        end

        page.within(find('.js-board-settings-sidebar')) do
          accept_confirm { find('[data-testid="remove-list"]').click }
        end

        click_button('Add issues')

        wait_for_requests

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
          find('.form-control').native.send_keys(:enter)

          wait_for_requests

          expect(page).to have_selector('.board-card', count: 1)
        end
      end

      it 'returns no issues' do
        page.within('.add-issues-modal') do
          find('.form-control').native.send_keys('testing search')
          find('.form-control').native.send_keys(:enter)

          wait_for_requests

          expect(page).not_to have_selector('.board-card')
          expect(page).not_to have_content("You haven't added any issues to your project yet")
        end
      end
    end

    context 'selecting issues' do
      it 'selects single issue' do
        page.within('.add-issues-modal') do
          first('.board-card .board-card-number').click

          page.within('.gl-tabs') do
            expect(page).to have_content('Selected issues 1')
          end
        end
      end

      it 'changes button text' do
        page.within('.add-issues-modal') do
          first('.board-card .board-card-number').click

          expect(first('.add-issues-footer .btn')).to have_content('Add 1 issue')
        end
      end

      it 'changes button text with plural' do
        page.within('.add-issues-modal') do
          all('.board-card .js-board-card-number-container').each do |el|
            el.click
          end

          expect(first('.add-issues-footer .btn')).to have_content('Add 2 issues')
        end
      end

      it 'shows only selected issues on selected tab' do
        page.within('.add-issues-modal') do
          first('.board-card .board-card-number').click

          click_link 'Selected issues'

          expect(page).to have_selector('.board-card', count: 1)
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

      it "selects all that aren't already selected" do
        page.within('.add-issues-modal') do
          first('.board-card .board-card-number').click

          expect(page).to have_selector('.is-active', count: 1)

          click_button 'Select all'

          expect(page).to have_selector('.is-active', count: 2)
        end
      end

      it 'unselects from selected tab' do
        page.within('.add-issues-modal') do
          first('.board-card .board-card-number').click

          click_link 'Selected issues'

          first('.board-card .board-card-number').click

          expect(page).not_to have_selector('.is-active')
        end
      end
    end

    context 'adding issues' do
      it 'adds to board' do
        page.within('.add-issues-modal') do
          first('.board-card .board-card-number').click

          click_button 'Add 1 issue'
        end

        page.within(find('.board:nth-child(2)')) do
          expect(page).to have_selector('.board-card')
        end
      end

      it 'adds to second list' do
        page.within('.add-issues-modal') do
          first('.board-card .board-card-number').click

          click_button planning.title

          click_link label.title

          click_button 'Add 1 issue'
        end

        page.within(find('.board:nth-child(3)')) do
          expect(page).to have_selector('.board-card')
        end
      end
    end
  end
end

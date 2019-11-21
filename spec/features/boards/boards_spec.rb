# frozen_string_literal: true

require 'spec_helper'

describe 'Issue Boards', :js do
  include DragTo
  include MobileHelpers

  let(:group) { create(:group, :nested) }
  let(:project) { create(:project, :public, namespace: group) }
  let(:board)   { create(:board, project: project) }
  let(:user)    { create(:user) }
  let!(:user2)  { create(:user) }

  before do
    project.add_maintainer(user)
    project.add_maintainer(user2)

    set_cookie('sidebar_collapsed', 'true')

    sign_in(user)
  end

  context 'no lists' do
    before do
      visit project_board_path(project, board)
      wait_for_requests
      expect(page).to have_selector('.board', count: 3)
    end

    it 'shows blank state' do
      expect(page).to have_content('Welcome to your Issue Board!')
    end

    it 'shows tooltip on add issues button' do
      button = page.find('.filter-dropdown-container button', text: 'Add issues')

      expect(button[:"data-original-title"]).to eq("Please add a list to your board first")
    end

    it 'hides the blank state when clicking nevermind button' do
      page.within(find('.board-blank-state')) do
        click_button("Nevermind, I'll use my own")
      end
      expect(page).to have_selector('.board', count: 2)
    end

    it 'creates default lists' do
      lists = ['Open', 'To Do', 'Doing', 'Closed']

      page.within(find('.board-blank-state')) do
        click_button('Add default lists')
      end
      wait_for_requests

      expect(page).to have_selector('.board', count: 4)

      page.all('.board').each_with_index do |list, i|
        expect(list.find('.board-title')).to have_content(lists[i])
      end
    end
  end

  context 'with lists' do
    let(:milestone) { create(:milestone, project: project) }

    let(:planning)    { create(:label, project: project, name: 'Planning', description: 'Test') }
    let(:development) { create(:label, project: project, name: 'Development') }
    let(:testing)     { create(:label, project: project, name: 'Testing') }
    let(:bug)         { create(:label, project: project, name: 'Bug') }
    let!(:backlog)    { create(:label, project: project, name: 'Backlog') }
    let!(:closed)       { create(:label, project: project, name: 'Closed') }
    let!(:accepting) { create(:label, project: project, name: 'Accepting Merge Requests') }
    let!(:a_plus) { create(:label, project: project, name: 'A+') }
    let!(:list1) { create(:list, board: board, label: planning, position: 0) }
    let!(:list2) { create(:list, board: board, label: development, position: 1) }

    let!(:confidential_issue) { create(:labeled_issue, :confidential, project: project, author: user, labels: [planning], relative_position: 9) }
    let!(:issue1) { create(:labeled_issue, project: project, title: 'aaa', description: '111', assignees: [user], labels: [planning], relative_position: 8) }
    let!(:issue2) { create(:labeled_issue, project: project, title: 'bbb', description: '222', author: user2, labels: [planning], relative_position: 7) }
    let!(:issue3) { create(:labeled_issue, project: project, title: 'ccc', description: '333', labels: [planning], relative_position: 6) }
    let!(:issue4) { create(:labeled_issue, project: project, title: 'ddd', description: '444', labels: [planning], relative_position: 5) }
    let!(:issue5) { create(:labeled_issue, project: project, title: 'eee', description: '555', labels: [planning], milestone: milestone, relative_position: 4) }
    let!(:issue6) { create(:labeled_issue, project: project, title: 'fff', description: '666', labels: [planning, development], relative_position: 3) }
    let!(:issue7) { create(:labeled_issue, project: project, title: 'ggg', description: '777', labels: [development], relative_position: 2) }
    let!(:issue8) { create(:closed_issue, project: project, title: 'hhh', description: '888') }
    let!(:issue9) { create(:labeled_issue, project: project, title: 'iii', description: '999', labels: [planning, testing, bug, accepting], relative_position: 1) }
    let!(:issue10) { create(:labeled_issue, project: project, title: 'issue +', description: 'A+ great issue', labels: [a_plus]) }

    before do
      visit project_board_path(project, board)

      wait_for_requests

      expect(page).to have_selector('.board', count: 4)
      expect(find('.board:nth-child(2)')).to have_selector('.board-card')
      expect(find('.board:nth-child(3)')).to have_selector('.board-card')
      expect(find('.board:nth-child(4)')).to have_selector('.board-card')
    end

    it 'shows description tooltip on list title', :quarantine do
      page.within('.board:nth-child(2)') do
        expect(find('.board-title span.has-tooltip')[:title]).to eq('Test')
      end
    end

    it 'shows issues in lists' do
      wait_for_board_cards(2, 8)
      wait_for_board_cards(3, 2)
    end

    it 'shows confidential issues with icon' do
      page.within(find('.board:nth-child(2)')) do
        expect(page).to have_selector('.confidential-icon', count: 1)
      end
    end

    it 'search closed list' do
      find('.filtered-search').set(issue8.title)
      find('.filtered-search').native.send_keys(:enter)

      wait_for_requests

      expect(find('.board:nth-child(2)')).to have_selector('.board-card', count: 0)
      expect(find('.board:nth-child(3)')).to have_selector('.board-card', count: 0)
      expect(find('.board:nth-child(4)')).to have_selector('.board-card', count: 1)
    end

    it 'search list' do
      find('.filtered-search').set(issue5.title)
      find('.filtered-search').native.send_keys(:enter)

      wait_for_requests

      expect(find('.board:nth-child(2)')).to have_selector('.board-card', count: 1)
      expect(find('.board:nth-child(3)')).to have_selector('.board-card', count: 0)
      expect(find('.board:nth-child(4)')).to have_selector('.board-card', count: 0)
    end

    it 'allows user to delete board' do
      page.within(find('.board:nth-child(2)')) do
        accept_confirm { find('.board-delete').click }
      end

      wait_for_requests

      expect(page).to have_selector('.board', count: 3)
    end

    it 'removes checkmark in new list dropdown after deleting' do
      click_button 'Add list'
      wait_for_requests

      find('.js-new-board-list').click

      page.within(find('.board:nth-child(2)')) do
        accept_confirm { find('.board-delete').click }
      end

      wait_for_requests

      expect(page).to have_selector('.board', count: 3)
    end

    it 'infinite scrolls list' do
      50.times do
        create(:labeled_issue, project: project, labels: [planning])
      end

      visit project_board_path(project, board)
      wait_for_requests

      page.within(find('.board:nth-child(2)')) do
        expect(page.find('.board-header')).to have_content('58')
        expect(page).to have_selector('.board-card', count: 20)
        expect(page).to have_content('Showing 20 of 58 issues')

        find('.board .board-list')
        evaluate_script("document.querySelectorAll('.board .board-list')[1].scrollTop = document.querySelectorAll('.board .board-list')[1].scrollHeight")
        wait_for_requests

        expect(page).to have_selector('.board-card', count: 40)
        expect(page).to have_content('Showing 40 of 58 issues')

        find('.board .board-list')
        evaluate_script("document.querySelectorAll('.board .board-list')[1].scrollTop = document.querySelectorAll('.board .board-list')[1].scrollHeight")
        wait_for_requests

        expect(page).to have_selector('.board-card', count: 58)
        expect(page).to have_content('Showing all issues')
      end
    end

    context 'closed' do
      it 'shows list of closed issues' do
        wait_for_board_cards(4, 1)
        wait_for_requests
      end

      it 'moves issue to closed' do
        drag(list_from_index: 1, list_to_index: 3)

        wait_for_board_cards(2, 7)
        wait_for_board_cards(3, 2)
        wait_for_board_cards(4, 2)

        expect(find('.board:nth-child(2)')).not_to have_content(issue9.title)
        expect(find('.board:nth-child(4)')).to have_selector('.board-card', count: 2)
        expect(find('.board:nth-child(4)')).to have_content(issue9.title)
        expect(find('.board:nth-child(4)')).not_to have_content(planning.title)
      end

      it 'removes all of the same issue to closed' do
        drag(list_from_index: 1, list_to_index: 3)

        wait_for_board_cards(2, 7)
        wait_for_board_cards(3, 2)
        wait_for_board_cards(4, 2)

        expect(find('.board:nth-child(2)')).not_to have_content(issue9.title)
        expect(find('.board:nth-child(4)')).to have_content(issue9.title)
        expect(find('.board:nth-child(4)')).not_to have_content(planning.title)
      end
    end

    context 'lists' do
      it 'changes position of list' do
        drag(list_from_index: 2, list_to_index: 1, selector: '.board-header')

        wait_for_board_cards(2, 2)
        wait_for_board_cards(3, 8)
        wait_for_board_cards(4, 1)

        expect(find('.board:nth-child(2)')).to have_content(development.title)
        expect(find('.board:nth-child(2)')).to have_content(planning.title)

        # Make sure list positions are preserved after a reload
        visit project_board_path(project, board)

        expect(find('.board:nth-child(2)')).to have_content(development.title)
        expect(find('.board:nth-child(2)')).to have_content(planning.title)
      end

      it 'dragging does not duplicate list' do
        selector = '.board:not(.is-ghost) .board-header'
        expect(page).to have_selector(selector, text: development.title, count: 1)

        drag(list_from_index: 2, list_to_index: 1, selector: '.board-header', perform_drop: false)

        expect(page).to have_selector(selector, text: development.title, count: 1)
      end

      it 'issue moves between lists and does not show the "Development" label since the card is in the "Development" list label' do
        drag(list_from_index: 1, from_index: 1, list_to_index: 2)

        wait_for_board_cards(2, 7)
        wait_for_board_cards(3, 2)
        wait_for_board_cards(4, 1)

        expect(find('.board:nth-child(3)')).to have_content(issue6.title)
        expect(find('.board:nth-child(3)').all('.board-card').last).not_to have_content(development.title)
      end

      it 'issue moves between lists and does not show the "Planning" label since the card is in the "Planning" list label' do
        drag(list_from_index: 2, list_to_index: 1)

        wait_for_board_cards(2, 9)
        wait_for_board_cards(3, 1)
        wait_for_board_cards(4, 1)

        expect(find('.board:nth-child(2)')).to have_content(issue7.title)
        expect(find('.board:nth-child(2)').all('.board-card').first).not_to have_content(planning.title)
      end

      it 'issue moves from closed' do
        drag(list_from_index: 2, list_to_index: 3)

        wait_for_board_cards(2, 8)
        wait_for_board_cards(3, 1)
        wait_for_board_cards(4, 2)

        expect(find('.board:nth-child(4)')).to have_content(issue8.title)
      end

      context 'issue card' do
        it 'shows assignee' do
          page.within(find('.board:nth-child(2)')) do
            expect(page).to have_selector('.avatar', count: 1)
          end
        end

        context 'list header' do
          let(:total_planning_issues) { "8" }

          it 'shows issue count on the list' do
            page.within(find(".board:nth-child(2)")) do
              expect(page.find('.js-issue-size')).to have_text(total_planning_issues)
              expect(page).not_to have_selector('.js-max-issue-size')
            end
          end
        end
      end

      context 'new list' do
        it 'shows all labels in new list dropdown' do
          click_button 'Add list'
          wait_for_requests

          page.within('.dropdown-menu-issues-board-new') do
            expect(page).to have_content(planning.title)
            expect(page).to have_content(development.title)
            expect(page).to have_content(testing.title)
          end
        end

        it 'creates new list for label' do
          click_button 'Add list'
          wait_for_requests

          page.within('.dropdown-menu-issues-board-new') do
            click_link testing.title
          end

          wait_for_requests

          expect(page).to have_selector('.board', count: 5)
        end

        it 'creates new list for Backlog label' do
          click_button 'Add list'
          wait_for_requests

          page.within('.dropdown-menu-issues-board-new') do
            click_link backlog.title
          end

          wait_for_requests

          expect(page).to have_selector('.board', count: 5)
        end

        it 'creates new list for Closed label' do
          click_button 'Add list'
          wait_for_requests

          page.within('.dropdown-menu-issues-board-new') do
            click_link closed.title
          end

          wait_for_requests

          expect(page).to have_selector('.board', count: 5)
        end

        it 'keeps dropdown open after adding new list' do
          click_button 'Add list'
          wait_for_requests

          page.within('.dropdown-menu-issues-board-new') do
            click_link closed.title
          end

          wait_for_requests

          expect(page).to have_css('#js-add-list.show')
        end

        it 'creates new list from a new label' do
          click_button 'Add list'

          wait_for_requests

          click_link 'Create project label'

          fill_in('new_label_name', with: 'Testing New Label - with list')

          first('.suggest-colors a').click

          click_button 'Create'

          wait_for_requests
          wait_for_requests

          expect(page).to have_selector('.board', count: 5)
        end
      end
    end

    context 'filtering' do
      it 'filters by author' do
        set_filter("author", user2.username)
        click_filter_link(user2.username)
        submit_filter

        wait_for_requests
        wait_for_board_cards(2, 1)
        wait_for_empty_boards((3..4))
      end

      it 'filters by assignee' do
        set_filter("assignee", user.username)
        click_filter_link(user.username)
        submit_filter

        wait_for_requests

        wait_for_board_cards(2, 1)
        wait_for_empty_boards((3..4))
      end

      it 'filters by milestone' do
        set_filter("milestone", "\"#{milestone.title}")
        click_filter_link(milestone.title)
        submit_filter

        wait_for_requests
        wait_for_board_cards(2, 1)
        wait_for_board_cards(3, 0)
        wait_for_board_cards(4, 0)
      end

      it 'filters by label' do
        set_filter("label", testing.title)
        click_filter_link(testing.title)
        submit_filter

        wait_for_requests
        wait_for_board_cards(2, 1)
        wait_for_empty_boards((3..4))
      end

      it 'filters by label with encoded character' do
        set_filter("label", a_plus.title)
        click_filter_link(a_plus.title)
        submit_filter

        wait_for_board_cards(1, 1)
        wait_for_empty_boards((2..4))
      end

      it 'filters by label with space after reload', :quarantine do
        set_filter("label", "\"#{accepting.title}")
        click_filter_link(accepting.title)
        submit_filter

        # Test after reload
        page.evaluate_script 'window.location.reload()'
        wait_for_board_cards(2, 1)
        wait_for_empty_boards((3..4))

        wait_for_requests

        page.within(find('.board:nth-child(2)')) do
          expect(page.find('.board-header')).to have_content('1')
          expect(page).to have_selector('.board-card', count: 1)
        end

        page.within(find('.board:nth-child(3)')) do
          expect(page.find('.board-header')).to have_content('0')
          expect(page).to have_selector('.board-card', count: 0)
        end
      end

      it 'removes filtered labels' do
        set_filter("label", testing.title)
        click_filter_link(testing.title)
        submit_filter

        wait_for_board_cards(2, 1)

        find('.clear-search').click
        submit_filter

        wait_for_board_cards(2, 8)
      end

      it 'infinite scrolls list with label filter' do
        50.times do
          create(:labeled_issue, project: project, labels: [planning, testing])
        end

        set_filter("label", testing.title)
        click_filter_link(testing.title)
        submit_filter

        wait_for_requests

        page.within(find('.board:nth-child(2)')) do
          expect(page.find('.board-header')).to have_content('51')
          expect(page).to have_selector('.board-card', count: 20)
          expect(page).to have_content('Showing 20 of 51 issues')

          find('.board .board-list')
          evaluate_script("document.querySelectorAll('.board .board-list')[1].scrollTop = document.querySelectorAll('.board .board-list')[1].scrollHeight")

          expect(page).to have_selector('.board-card', count: 40)
          expect(page).to have_content('Showing 40 of 51 issues')

          find('.board .board-list')
          evaluate_script("document.querySelectorAll('.board .board-list')[1].scrollTop = document.querySelectorAll('.board .board-list')[1].scrollHeight")

          expect(page).to have_selector('.board-card', count: 51)
          expect(page).to have_content('Showing all issues')
        end
      end

      it 'filters by multiple labels', :quarantine do
        set_filter("label", testing.title)
        click_filter_link(testing.title)

        set_filter("label", bug.title)
        click_filter_link(bug.title)

        submit_filter

        wait_for_requests

        wait_for_board_cards(2, 1)
        wait_for_empty_boards((3..4))
      end

      it 'filters by clicking label button on issue' do
        page.within(find('.board:nth-child(2)')) do
          expect(page).to have_selector('.board-card', count: 8)
          expect(find('.board-card', match: :first)).to have_content(bug.title)
          click_button(bug.title)
          wait_for_requests
        end

        page.within('.tokens-container') do
          expect(page).to have_content(bug.title)
        end

        wait_for_requests

        wait_for_board_cards(2, 1)
        wait_for_empty_boards((3..4))
      end

      it 'removes label filter by clicking label button on issue' do
        page.within(find('.board:nth-child(2)')) do
          page.within(find('.board-card', match: :first)) do
            click_button(bug.title)
          end

          wait_for_requests

          expect(page).to have_selector('.board-card', count: 1)
        end

        wait_for_requests
      end
    end
  end

  context 'keyboard shortcuts' do
    before do
      visit project_board_path(project, board)
      wait_for_requests
    end

    it 'allows user to use keyboard shortcuts' do
      find('body').native.send_keys('i')
      expect(page).to have_content('New Issue')
    end
  end

  context 'signed out user' do
    before do
      sign_out(:user)
      visit project_board_path(project, board)
      wait_for_requests
    end

    it 'displays lists' do
      expect(page).to have_selector('.board')
    end

    it 'does not show create new list' do
      expect(page).not_to have_button('.js-new-board-list')
    end

    it 'does not allow dragging' do
      expect(page).not_to have_selector('.user-can-drag')
    end
  end

  context 'as guest user' do
    let(:user_guest) { create(:user) }

    before do
      project.add_guest(user_guest)
      sign_out(:user)
      sign_in(user_guest)
      visit project_board_path(project, board)
      wait_for_requests
    end

    it 'does not show create new list' do
      expect(page).not_to have_selector('.js-new-board-list')
    end
  end

  def drag(selector: '.board-list', list_from_index: 0, from_index: 0, to_index: 0, list_to_index: 0, perform_drop: true)
    # ensure there is enough horizontal space for four boards
    resize_window(2000, 800)

    drag_to(selector: selector,
            scrollable: '#board-app',
            list_from_index: list_from_index,
            from_index: from_index,
            to_index: to_index,
            list_to_index: list_to_index,
            perform_drop: perform_drop)
  end

  def wait_for_board_cards(board_number, expected_cards)
    page.within(find(".board:nth-child(#{board_number})")) do
      expect(page.find('.board-header')).to have_content(expected_cards.to_s)
      expect(page).to have_selector('.board-card', count: expected_cards)
    end
  end

  def wait_for_empty_boards(board_numbers)
    board_numbers.each do |board|
      wait_for_board_cards(board, 0)
    end
  end

  def set_filter(type, text)
    find('.filtered-search').native.send_keys("#{type}:#{text}")
  end

  def submit_filter
    find('.filtered-search').native.send_keys(:enter)
  end

  def click_filter_link(link_text)
    page.within('.filtered-search-box') do
      expect(page).to have_button(link_text)

      click_button(link_text)
    end
  end
end

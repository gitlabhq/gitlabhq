require 'rails_helper'

describe 'Issue Boards', feature: true, js: true do
  include WaitForAjax

  let(:project) { create(:empty_project, :public) }
  let(:user)    { create(:user) }
  let!(:user2)  { create(:user) }

  before do
    project.create_board
    project.board.lists.create(list_type: :backlog)
    project.board.lists.create(list_type: :done)

    project.team << [user, :master]
    project.team << [user2, :master]

    login_as(user)
  end

  context 'no lists' do
    before do
      visit namespace_project_board_path(project.namespace, project)
      wait_for_vue_resource
      expect(page).to have_selector('.board', count: 3)
    end

    it 'shows blank state' do
      expect(page).to have_content('Welcome to your Issue Board!')
    end

    it 'hides the blank state when clicking nevermind button' do
      page.within(find('.board-blank-state')) do
        click_button("Nevermind, I'll use my own")
      end
      expect(page).to have_selector('.board', count: 2)
    end

    it 'creates default lists' do
      lists = ['Backlog', 'Development', 'Testing', 'Production', 'Ready', 'Done']

      page.within(find('.board-blank-state')) do
        click_button('Add default lists')
      end
      wait_for_vue_resource

      expect(page).to have_selector('.board', count: 6)

      page.all('.board').each_with_index do |list, i|
        expect(list.find('.board-title')).to have_content(lists[i])
      end
    end
  end

  context 'with lists' do
    let(:milestone) { create(:milestone, project: project) }

    let(:planning)    { create(:label, project: project, name: 'Planning') }
    let(:development) { create(:label, project: project, name: 'Development') }
    let(:testing)     { create(:label, project: project, name: 'Testing') }
    let(:bug)         { create(:label, project: project, name: 'Bug') }
    let!(:backlog)    { create(:label, project: project, name: 'Backlog') }
    let!(:done)       { create(:label, project: project, name: 'Done') }

    let!(:list1) { create(:list, board: project.board, label: planning, position: 0) }
    let!(:list2) { create(:list, board: project.board, label: development, position: 1) }

    let!(:confidential_issue) { create(:issue, :confidential, project: project, author: user) }
    let!(:issue1) { create(:issue, project: project, assignee: user) }
    let!(:issue2) { create(:issue, project: project, author: user2) }
    let!(:issue3) { create(:issue, project: project) }
    let!(:issue4) { create(:issue, project: project) }
    let!(:issue5) { create(:labeled_issue, project: project, labels: [planning], milestone: milestone) }
    let!(:issue6) { create(:labeled_issue, project: project, labels: [planning, development]) }
    let!(:issue7) { create(:labeled_issue, project: project, labels: [development]) }
    let!(:issue8) { create(:closed_issue, project: project) }
    let!(:issue9) { create(:labeled_issue, project: project, labels: [testing, bug]) }

    before do
      visit namespace_project_board_path(project.namespace, project)

      wait_for_vue_resource

      expect(page).to have_selector('.board', count: 4)
      expect(find('.board:nth-child(1)')).to have_selector('.card')
      expect(find('.board:nth-child(2)')).to have_selector('.card')
      expect(find('.board:nth-child(3)')).to have_selector('.card')
      expect(find('.board:nth-child(4)')).to have_selector('.card')
    end

    it 'shows lists' do
      expect(page).to have_selector('.board', count: 4)
    end

    it 'shows issues in lists' do
      page.within(find('.board:nth-child(2)')) do
        expect(page.find('.board-header')).to have_content('2')
        expect(page).to have_selector('.card', count: 2)
      end

      page.within(find('.board:nth-child(3)')) do
        expect(page.find('.board-header')).to have_content('2')
        expect(page).to have_selector('.card', count: 2)
      end
    end

    it 'shows confidential issues with icon' do
      page.within(find('.board', match: :first)) do
        expect(page).to have_selector('.confidential-icon', count: 1)
      end
    end

    it 'allows user to delete board' do
      page.within(find('.board:nth-child(2)')) do
        find('.board-delete').click
      end

      wait_for_vue_resource

      expect(page).to have_selector('.board', count: 3)
    end

    it 'removes checkmark in new list dropdown after deleting' do
      click_button 'Create new list'
      wait_for_ajax

      page.within(find('.board:nth-child(2)')) do
        find('.board-delete').click
      end

      wait_for_vue_resource

      expect(page).to have_selector('.board', count: 3)
      expect(find(".js-board-list-#{planning.id}", visible: false)).not_to have_css('.is-active')
    end

    it 'infinite scrolls list' do
      50.times do
        create(:issue, project: project)
      end

      visit namespace_project_board_path(project.namespace, project)
      wait_for_vue_resource

      page.within(find('.board', match: :first)) do
        expect(page.find('.board-header')).to have_content('56')
        expect(page).to have_selector('.card', count: 20)
        expect(page).to have_content('Showing 20 of 56 issues')

        evaluate_script("document.querySelectorAll('.board .board-list')[0].scrollTop = document.querySelectorAll('.board .board-list')[0].scrollHeight")
        wait_for_vue_resource(spinner: false)

        expect(page).to have_selector('.card', count: 40)
        expect(page).to have_content('Showing 40 of 56 issues')

        evaluate_script("document.querySelectorAll('.board .board-list')[0].scrollTop = document.querySelectorAll('.board .board-list')[0].scrollHeight")
        wait_for_vue_resource(spinner: false)

        expect(page).to have_selector('.card', count: 56)
        expect(page).to have_content('Showing all issues')
      end
    end

    context 'backlog' do
      it 'shows issues in backlog with no labels' do
        page.within(find('.board', match: :first)) do
          expect(page.find('.board-header')).to have_content('6')
          expect(page).to have_selector('.card', count: 6)
        end
      end

      it 'is searchable' do
        page.within(find('.board', match: :first)) do
          find('.form-control').set issue1.title

          wait_for_vue_resource(spinner: false)

          expect(page).to have_selector('.card', count: 1)
        end
      end

      it 'clears search' do
        page.within(find('.board', match: :first)) do
          find('.form-control').set issue1.title

          expect(page).to have_selector('.card', count: 1)

          find('.board-search-clear-btn').click
        end

        wait_for_vue_resource

        page.within(find('.board', match: :first)) do
          expect(page).to have_selector('.card', count: 6)
        end
      end

      it 'moves issue from backlog into list' do
        drag_to(list_to_index: 1)

        page.within(find('.board', match: :first)) do
          expect(page.find('.board-header')).to have_content('5')
          expect(page).to have_selector('.card', count: 5)
        end

        wait_for_vue_resource

        page.within(find('.board:nth-child(2)')) do
          expect(page.find('.board-header')).to have_content('3')
          expect(page).to have_selector('.card', count: 3)
        end
      end
    end

    context 'done' do
      it 'shows list of done issues' do
        expect(find('.board:nth-child(4)')).to have_selector('.card', count: 1)
      end

      it 'moves issue to done' do
        drag_to(list_from_index: 0, list_to_index: 3)

        expect(find('.board:nth-child(4)')).to have_selector('.card', count: 2)
        expect(find('.board:nth-child(4)')).to have_content(issue9.title)
        expect(find('.board:nth-child(4)')).not_to have_content(planning.title)
      end

      it 'removes all of the same issue to done' do
        drag_to(list_from_index: 1, list_to_index: 3)

        expect(find('.board:nth-child(2)')).to have_selector('.card', count: 1)
        expect(find('.board:nth-child(3)')).to have_selector('.card', count: 1)
        expect(find('.board:nth-child(4)')).to have_content(issue6.title)
        expect(find('.board:nth-child(4)')).not_to have_content(planning.title)
      end
    end

    context 'lists' do
      it 'changes position of list' do
        drag_to(list_from_index: 1, list_to_index: 2, selector: '.board-header')

        expect(find('.board:nth-child(2)')).to have_content(development.title)
        expect(find('.board:nth-child(2)')).to have_content(planning.title)
      end

      it 'issue moves between lists' do
        drag_to(list_from_index: 1, card_index: 1, list_to_index: 2)

        expect(find('.board:nth-child(2)')).to have_selector('.card', count: 1)
        expect(find('.board:nth-child(3)')).to have_selector('.card', count: 3)
        expect(find('.board:nth-child(3)')).to have_content(issue6.title)
        expect(find('.board:nth-child(3)').all('.card').last).not_to have_content(development.title)
      end

      it 'issue moves between lists' do
        drag_to(list_from_index: 2, list_to_index: 1)

        expect(find('.board:nth-child(2)')).to have_selector('.card', count: 3)
        expect(find('.board:nth-child(3)')).to have_selector('.card', count: 1)
        expect(find('.board:nth-child(2)')).to have_content(issue7.title)
        expect(find('.board:nth-child(2)').all('.card').first).not_to have_content(planning.title)
      end

      it 'issue moves from done' do
        drag_to(list_from_index: 3, list_to_index: 1)

        expect(find('.board:nth-child(2)')).to have_selector('.card', count: 3)
        expect(find('.board:nth-child(2)')).to have_content(issue8.title)
      end

      context 'issue card' do
        it 'shows assignee' do
          page.within(find('.board', match: :first)) do
            expect(page).to have_selector('.avatar', count: 1)
          end
        end
      end

      context 'new list' do
        it 'shows all labels in new list dropdown' do
          click_button 'Create new list'
          wait_for_ajax

          page.within('.dropdown-menu-issues-board-new') do
            expect(page).to have_content(planning.title)
            expect(page).to have_content(development.title)
            expect(page).to have_content(testing.title)
          end
        end

        it 'creates new list for label' do
          click_button 'Create new list'
          wait_for_ajax

          page.within('.dropdown-menu-issues-board-new') do
            click_link testing.title
          end

          wait_for_vue_resource

          expect(page).to have_selector('.board', count: 5)
        end

        it 'creates new list for Backlog label' do
          click_button 'Create new list'
          wait_for_ajax

          page.within('.dropdown-menu-issues-board-new') do
            click_link backlog.title
          end

          wait_for_vue_resource

          expect(page).to have_selector('.board', count: 5)
        end

        it 'creates new list for Done label' do
          click_button 'Create new list'
          wait_for_ajax

          page.within('.dropdown-menu-issues-board-new') do
            click_link done.title
          end

          wait_for_vue_resource

          expect(page).to have_selector('.board', count: 5)
        end

        it 'moves issues from backlog into new list' do
          page.within(find('.board', match: :first)) do
            expect(page.find('.board-header')).to have_content('6')
            expect(page).to have_selector('.card', count: 6)
          end

          click_button 'Create new list'
          wait_for_ajax

          page.within('.dropdown-menu-issues-board-new') do
            click_link testing.title
          end

          wait_for_vue_resource

          page.within(find('.board', match: :first)) do
            expect(page.find('.board-header')).to have_content('5')
            expect(page).to have_selector('.card', count: 5)
          end
        end
      end
    end

    context 'filtering' do
      it 'filters by author' do
        page.within '.issues-filters' do
          click_button('Author')
          wait_for_ajax

          page.within '.dropdown-menu-author' do
            click_link(user2.name)
          end
          wait_for_vue_resource(spinner: false)

          expect(find('.js-author-search')).to have_content(user2.name)
        end

        wait_for_vue_resource

        page.within(find('.board', match: :first)) do
          expect(page.find('.board-header')).to have_content('1')
          expect(page).to have_selector('.card', count: 1)
        end

        page.within(find('.board:nth-child(2)')) do
          expect(page.find('.board-header')).to have_content('0')
          expect(page).to have_selector('.card', count: 0)
        end
      end

      it 'filters by assignee' do
        page.within '.issues-filters' do
          click_button('Assignee')
          wait_for_ajax

          page.within '.dropdown-menu-assignee' do
            click_link(user.name)
          end
          wait_for_vue_resource(spinner: false)

          expect(find('.js-assignee-search')).to have_content(user.name)
        end

        wait_for_vue_resource

        page.within(find('.board', match: :first)) do
          expect(page.find('.board-header')).to have_content('1')
          expect(page).to have_selector('.card', count: 1)
        end

        page.within(find('.board:nth-child(2)')) do
          expect(page.find('.board-header')).to have_content('0')
          expect(page).to have_selector('.card', count: 0)
        end
      end

      it 'filters by milestone' do
        page.within '.issues-filters' do
          click_button('Milestone')
          wait_for_ajax

          page.within '.milestone-filter' do
            click_link(milestone.title)
          end
          wait_for_vue_resource(spinner: false)

          expect(find('.js-milestone-select')).to have_content(milestone.title)
        end

        wait_for_vue_resource

        page.within(find('.board', match: :first)) do
          expect(page.find('.board-header')).to have_content('0')
          expect(page).to have_selector('.card', count: 0)
        end

        page.within(find('.board:nth-child(2)')) do
          expect(page.find('.board-header')).to have_content('1')
          expect(page).to have_selector('.card', count: 1)
        end
      end

      it 'filters by label' do
        page.within '.issues-filters' do
          click_button('Label')
          wait_for_ajax

          page.within '.dropdown-menu-labels' do
            click_link(testing.title)
            wait_for_vue_resource(spinner: false)
            find('.dropdown-menu-close').click
          end
        end

        wait_for_vue_resource

        page.within(find('.board', match: :first)) do
          expect(page.find('.board-header')).to have_content('1')
          expect(page).to have_selector('.card', count: 1)
        end

        page.within(find('.board:nth-child(2)')) do
          expect(page.find('.board-header')).to have_content('0')
          expect(page).to have_selector('.card', count: 0)
        end
      end

      it 'infinite scrolls list with label filter' do
        50.times do
          create(:labeled_issue, project: project, labels: [testing])
        end

        page.within '.issues-filters' do
          click_button('Label')
          wait_for_ajax

          page.within '.dropdown-menu-labels' do
            click_link(testing.title)
            wait_for_vue_resource(spinner: false)
            find('.dropdown-menu-close').click
          end
        end

        wait_for_vue_resource

        page.within(find('.board', match: :first)) do
          expect(page.find('.board-header')).to have_content('51')
          expect(page).to have_selector('.card', count: 20)
          expect(page).to have_content('Showing 20 of 51 issues')

          evaluate_script("document.querySelectorAll('.board .board-list')[0].scrollTop = document.querySelectorAll('.board .board-list')[0].scrollHeight")

          expect(page).to have_selector('.card', count: 40)
          expect(page).to have_content('Showing 40 of 51 issues')

          evaluate_script("document.querySelectorAll('.board .board-list')[0].scrollTop = document.querySelectorAll('.board .board-list')[0].scrollHeight")

          expect(page).to have_selector('.card', count: 51)
          expect(page).to have_content('Showing all issues')
        end
      end

      it 'filters by multiple labels' do
        page.within '.issues-filters' do
          click_button('Label')
          wait_for_ajax

          page.within(find('.dropdown-menu-labels')) do
            click_link(testing.title)
            wait_for_vue_resource(spinner: false)
            click_link(bug.title)
            wait_for_vue_resource(spinner: false)
            find('.dropdown-menu-close').click
          end
        end

        wait_for_vue_resource

        page.within(find('.board', match: :first)) do
          expect(page.find('.board-header')).to have_content('1')
          expect(page).to have_selector('.card', count: 1)
        end

        page.within(find('.board:nth-child(2)')) do
          expect(page.find('.board-header')).to have_content('0')
          expect(page).to have_selector('.card', count: 0)
        end
      end

      it 'filters by no label' do
        page.within '.issues-filters' do
          click_button('Label')
          wait_for_ajax

          page.within '.dropdown-menu-labels' do
            click_link("No Label")
            wait_for_vue_resource(spinner: false)
            find('.dropdown-menu-close').click
          end
        end

        wait_for_vue_resource

        page.within(find('.board', match: :first)) do
          expect(page.find('.board-header')).to have_content('5')
          expect(page).to have_selector('.card', count: 5)
        end

        page.within(find('.board:nth-child(2)')) do
          expect(page.find('.board-header')).to have_content('0')
          expect(page).to have_selector('.card', count: 0)
        end
      end

      it 'filters by clicking label button on issue' do
        page.within(find('.board', match: :first)) do
          expect(page).to have_selector('.card', count: 6)
          expect(find('.card', match: :first)).to have_content(bug.title)
          click_button(bug.title)
          wait_for_vue_resource(spinner: false)
        end

        wait_for_vue_resource

        page.within(find('.board', match: :first)) do
          expect(page.find('.board-header')).to have_content('1')
          expect(page).to have_selector('.card', count: 1)
        end

        page.within(find('.board:nth-child(2)')) do
          expect(page.find('.board-header')).to have_content('0')
          expect(page).to have_selector('.card', count: 0)
        end

        page.within('.labels-filter') do
          expect(find('.dropdown-toggle-text')).to have_content(bug.title)
        end
      end

      it 'removes label filter by clicking label button on issue' do
        page.within(find('.board', match: :first)) do
          page.within(find('.card', match: :first)) do
            click_button(bug.title)
          end
          wait_for_vue_resource(spinner: false)

          expect(page).to have_selector('.card', count: 1)
        end

        wait_for_vue_resource

        page.within('.labels-filter') do
          expect(find('.dropdown-toggle-text')).to have_content(bug.title)
        end
      end
    end
  end

  context 'keyboard shortcuts' do
    before do
      visit namespace_project_board_path(project.namespace, project)
      wait_for_vue_resource
    end

    it 'allows user to use keyboard shortcuts' do
      find('.boards-list').native.send_keys('i')
      expect(page).to have_content('New Issue')
    end
  end

  context 'signed out user' do
    before do
      logout
      visit namespace_project_board_path(project.namespace, project)
      wait_for_vue_resource
    end

    it 'does not show create new list' do
      expect(page).not_to have_selector('.js-new-board-list')
    end
  end

  context 'as guest user' do
    let(:user_guest) { create(:user) }

    before do
      project.team << [user_guest, :guest]
      logout
      login_as(user_guest)
      visit namespace_project_board_path(project.namespace, project)
      wait_for_vue_resource
    end

    it 'does not show create new list' do
      expect(page).not_to have_selector('.js-new-board-list')
    end
  end

  def drag_to(list_from_index: 0, card_index: 0, to_index: 0, list_to_index: 0, selector: '.board-list')
    evaluate_script("simulateDrag({scrollable: document.getElementById('board-app'), from: {el: $('#{selector}').eq(#{list_from_index}).get(0), index: #{card_index}}, to: {el: $('.board-list').eq(#{list_to_index}).get(0), index: #{to_index}}});")

    Timeout.timeout(Capybara.default_max_wait_time) do
      loop until page.evaluate_script('window.SIMULATE_DRAG_ACTIVE').zero?
    end

    wait_for_vue_resource
  end

  def wait_for_vue_resource(spinner: true)
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop until page.evaluate_script('Vue.activeResources').zero?
    end

    if spinner
      expect(find('.boards-list')).not_to have_selector('.fa-spinner')
    end
  end
end

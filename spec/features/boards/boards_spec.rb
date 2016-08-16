require 'rails_helper'

describe 'Issue Boards', feature: true, js: true do
  include WaitForAjax

  let(:project)   { create(:project) }
  let(:user)      { create(:user) }
  let!(:user2)    { create(:user) }
  let!(:board)    { Boards::CreateService.new(project, user).execute }

  before do
    project.team << [user, :master]
    project.team << [user2, :master]
    login_as(user)
  end

  context 'no lists' do
    before do
      visit namespace_project_board_path(project.namespace, project)
    end

    it 'shows blank state' do
      expect(page).to have_selector('.board', count: 3)
      expect(page).to have_content('Welcome to your Issue Board!')
    end

    it 'hides the blank state when clicking nevermind button' do
      page.within('.board-blank-state') do
        click_button("Nevermind, I'll use my own")
      end
      expect(page).to have_selector('.board', count: 2)
    end

    it 'creates default lists' do
      lists = ['Backlog', 'Development', 'Testing', 'Production', 'Ready', 'Done']

      page.within('.board-blank-state') do
        click_button('Add default lists')
      end
      expect(page).to have_selector('.board', count: 6)

      page.all('.board').each_with_index do |list, i|
        expect(list.find('.board-title')).to have_content(lists[i])
      end
    end
  end

  context 'with lists' do
    let(:milestone)           { create(:milestone, project: project) }

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
    end

    it 'shows lists' do
      wait_for_vue_resource
      expect(page).to have_selector('.board', count: 4)
    end

    it 'shows issues in lists' do
      page.within(all('.board')[1]) do
        expect(page.find('.board-header')).to have_content('2')
        expect(page).to have_selector('.card', count: 2)
      end

      page.within(all('.board')[2]) do
        expect(page.find('.board-header')).to have_content('2')
        expect(page).to have_selector('.card', count: 2)
      end
    end

    it 'shows confidential issues with icon' do
      page.within(first('.board')) do
        expect(page).to have_selector('.confidential-icon', count: 1)
      end
    end

    it 'allows user to delete board' do
      page.within(all('.board')[1]) do
        find('.board-delete').click
      end
      expect(page).to have_selector('.board', count: 3)
    end

    it 'removes checkmark in new list dropdown after deleting' do
      click_button 'Create new list'
      wait_for_ajax

      page.within(all('.board')[1]) do
        find('.board-delete').click
      end
      expect(page).to have_selector('.board', count: 3)

      expect(find(".js-board-list-#{planning.id}", visible: false)).not_to have_css('.is-active')
    end

    it 'infinite scrolls list' do
      50.times do
        create(:issue, project: project)
      end

      visit namespace_project_board_path(project.namespace, project)
      wait_for_vue_resource

      page.within(first('.board')) do
        expect(page.find('.board-header')).to have_content('20')
        expect(page).to have_selector('.card', count: 20)

        evaluate_script("document.querySelectorAll('.board .board-list')[0].scrollTop = document.querySelectorAll('.board .board-list')[0].scrollHeight")

        expect(page.find('.board-header')).to have_content('40')
        expect(page).to have_selector('.card', count: 40)
      end
    end

    context 'backlog' do
      it 'shows issues in backlog with no labels' do
        page.within(first('.board')) do
          expect(page.find('.board-header')).to have_content('6')
          expect(page).to have_selector('.card', count: 6)
        end
      end

      it 'is searchable' do
        page.within(first('.board')) do
          find('.form-control').set issue1.title

          expect(page).to have_selector('.card', count: 1)
        end
      end

      it 'clears search' do
        page.within(first('.board')) do
          find('.form-control').set issue1.title

          expect(page).to have_selector('.card', count: 1)

          find('.board-search-clear-btn').click

          wait_for_vue_resource

          expect(page).to have_selector('.card', count: 6)
        end
      end

      it 'moves issue from backlog into list' do
        drag_to(list_to_index: 1)

        page.within(first('.board')) do
          expect(page.find('.board-header')).to have_content('5')
          expect(page).to have_selector('.card', count: 5)
        end

        page.within(all('.board')[1]) do
          expect(page.find('.board-header')).to have_content('3')
          expect(page).to have_selector('.card', count: 3)
        end
      end
    end

    context 'done' do
      it 'shows list of done issues' do
        expect(all('.board').last).to have_selector('.card', count: 1)
      end

      it 'moves issue to done' do
        drag_to(list_from_index: 0, list_to_index: 3)

        expect(all('.board').last).to have_selector('.card', count: 2)
        expect(all('.board').last).to have_content(issue9.title)
        expect(all('.board').last).not_to have_content(planning.title)
      end

      it 'removes all of the same issue to done' do
        drag_to(list_from_index: 1, list_to_index: 3)

        expect(all('.board')[1]).to have_selector('.card', count: 1)
        expect(all('.board')[2]).to have_selector('.card', count: 1)
        expect(all('.board').last).to have_content(issue6.title)
        expect(all('.board').last).not_to have_content(planning.title)
      end
    end

    context 'lists' do
      it 'changes position of list' do
        drag_to(list_from_index: 1, list_to_index: 2, selector: '.js-board-handle')

        expect(all('.board')[1]).to have_content(development.title)
        expect(all('.board')[1]).to have_content(planning.title)
      end

      it 'moves between lists' do
        drag_to(list_from_index: 1, card_index: 1, list_to_index: 2)

        expect(all('.board')[1]).to have_selector('.card', count: 1)
        expect(all('.board')[2]).to have_selector('.card', count: 3)
        expect(all('.board')[2]).to have_content(issue6.title)
        expect(all('.board')[2].all('.card').last).not_to have_content(development.title)
      end

      it 'moves between lists' do
        drag_to(list_from_index: 2, list_to_index: 1)

        expect(all('.board')[1]).to have_selector('.card', count: 3)
        expect(all('.board')[2]).to have_selector('.card', count: 1)
        expect(all('.board')[1]).to have_content(issue7.title)
        expect(all('.board')[1].all('.card').first).not_to have_content(planning.title)
      end

      it 'moves from done' do
        drag_to(list_from_index: 3, list_to_index: 1)

        expect(all('.board')[1]).to have_selector('.card', count: 3)
        expect(all('.board')[1]).to have_content(issue8.title)
      end

      context 'issue card' do
        it 'shows assignee' do
          page.within(first('.board')) do
            expect(page).to have_selector('.avatar', count: 1)
          end
        end
      end

      context 'new list' do
        it 'shows all labels in new list dropdown' do
          click_button 'Create new list'

          page.within('.dropdown-menu-issues-board-new') do
            expect(page).to have_content(planning.title)
            expect(page).to have_content(development.title)
            expect(page).to have_content(testing.title)
          end
        end

        it 'creates new list for label' do
          click_button 'Create new list'

          page.within('.dropdown-menu-issues-board-new') do
            click_link testing.title
          end

          expect(page).to have_selector('.board', count: 5)
        end

        it 'creates new list for Backlog label' do
          click_button 'Create new list'

          page.within('.dropdown-menu-issues-board-new') do
            click_link backlog.title
          end

          expect(page).to have_selector('.board', count: 5)
        end

        it 'creates new list for Done label' do
          click_button 'Create new list'

          page.within('.dropdown-menu-issues-board-new') do
            click_link done.title
          end

          expect(page).to have_selector('.board', count: 5)
        end

        it 'moves issues from backlog into new list' do
          page.within(first('.board')) do
            expect(page.find('.board-header')).to have_content('6')
            expect(page).to have_selector('.card', count: 6)
          end

          click_button 'Create new list'

          page.within('.dropdown-menu-issues-board-new') do
            click_link testing.title
          end

          page.within(first('.board')) do
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

          page.within '.dropdown-menu-author' do
            click_link(user2.name)
          end

          expect(find('.js-author-search')).to have_content(user2.name)
        end

        wait_for_vue_resource

        page.within(first('.board')) do
          expect(page.find('.board-header')).to have_content('1')
          expect(page).to have_selector('.card', count: 1)
        end

        page.within(all('.board')[1]) do
          expect(page.find('.board-header')).to have_content('0')
          expect(page).to have_selector('.card', count: 0)
        end
      end

      it 'filters by assignee' do
        page.within '.issues-filters' do
          click_button('Assignee')

          page.within '.dropdown-menu-assignee' do
            click_link(user.name)
          end

          expect(find('.js-assignee-search')).to have_content(user.name)
        end

        wait_for_vue_resource

        page.within(first('.board')) do
          expect(page.find('.board-header')).to have_content('1')
          expect(page).to have_selector('.card', count: 1)
        end

        page.within(all('.board')[1]) do
          expect(page.find('.board-header')).to have_content('0')
          expect(page).to have_selector('.card', count: 0)
        end
      end

      it 'filters by milestone' do
        page.within '.issues-filters' do
          click_button('Milestone')

          page.within '.milestone-filter' do
            click_link(milestone.title)
          end

          expect(find('.js-milestone-select')).to have_content(milestone.title)
        end

        wait_for_vue_resource

        page.within(first('.board')) do
          expect(page.find('.board-header')).to have_content('0')
          expect(page).to have_selector('.card', count: 0)
        end

        page.within(all('.board')[1]) do
          expect(page.find('.board-header')).to have_content('1')
          expect(page).to have_selector('.card', count: 1)
        end
      end

      it 'filters by label' do
        page.within '.issues-filters' do
          click_button('Label')

          page.within '.dropdown-menu-labels' do
            click_link(testing.title)
            find('.dropdown-menu-close').click
          end
        end

        wait_for_vue_resource

        page.within(first('.board')) do
          expect(page.find('.board-header')).to have_content('1')
          expect(page).to have_selector('.card', count: 1)
        end

        page.within(all('.board')[1]) do
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

          page.within '.dropdown-menu-labels' do
            click_link(testing.title)
            find('.dropdown-menu-close').click
          end
        end

        wait_for_vue_resource

        page.within(first('.board')) do
          expect(page.find('.board-header')).to have_content('20')
          expect(page).to have_selector('.card', count: 20)

          evaluate_script("document.querySelectorAll('.board .board-list')[0].scrollTop = document.querySelectorAll('.board .board-list')[0].scrollHeight")

          wait_for_vue_resource

          expect(page.find('.board-header')).to have_content('40')
          expect(page).to have_selector('.card', count: 40)
        end
      end

      it 'filters by multiple labels' do
        page.within '.issues-filters' do
          click_button('Label')

          page.within '.dropdown-menu-labels' do
            click_link(testing.title)
            click_link(bug.title)
            find('.dropdown-menu-close').click
          end
        end

        wait_for_vue_resource

        page.within(first('.board')) do
          expect(page.find('.board-header')).to have_content('1')
          expect(page).to have_selector('.card', count: 1)
        end

        page.within(all('.board')[1]) do
          expect(page.find('.board-header')).to have_content('0')
          expect(page).to have_selector('.card', count: 0)
        end
      end

      it 'filters by no label' do
        page.within '.issues-filters' do
          click_button('Label')

          page.within '.dropdown-menu-labels' do
            click_link("No Label")
            find('.dropdown-menu-close').click
          end
        end

        wait_for_vue_resource

        page.within(first('.board')) do
          expect(page.find('.board-header')).to have_content('5')
          expect(page).to have_selector('.card', count: 5)
        end

        page.within(all('.board')[1]) do
          expect(page.find('.board-header')).to have_content('0')
          expect(page).to have_selector('.card', count: 0)
        end
      end

      it 'filters by clicking label button on issue' do
        page.within '.issues-filters' do
          click_button('Label')

          page.within '.dropdown-menu-labels' do
            click_link(bug.title)
            find('.dropdown-menu-close').click
          end
        end

        wait_for_vue_resource

        page.within(first('.board')) do
          expect(page.find('.board-header')).to have_content('1')
          expect(page).to have_selector('.card', count: 1)
        end

        page.within(all('.board')[1]) do
          expect(page.find('.board-header')).to have_content('0')
          expect(page).to have_selector('.card', count: 0)
        end

        page.within(first('.board')) do
          click_button(bug.title)

          expect(page).to have_selector('.card', count: 6)
        end

        page.within('.labels-filter') do
          expect(find('.dropdown-toggle-text')).not_to have_content(bug.title)
        end
      end

      it 'removes label filter by clicking label button on issue' do
        page.within(first('.board')) do
          page.within(first('.card')) do
            click_button(bug.title)
          end

          expect(page).to have_selector('.card', count: 1)
        end

        wait_for_vue_resource

        page.within('.labels-filter') do
          expect(find('.dropdown-toggle-text')).to have_content(bug.title)
        end
      end
    end
  end

  def drag_to(list_from_index: 0, card_index: 0, to_index: 0, list_to_index: 0, selector: '.board-list')
    evaluate_script("simulateDrag({scrollable: document.getElementById('board-app'), from: {el: $('#{selector}').eq(#{list_from_index}).get(0), index: #{card_index}}, to: {el: $('.board-list').eq(#{list_to_index}).get(0), index: #{to_index}}});")

    Timeout.timeout(Capybara.default_max_wait_time) do
      loop until page.evaluate_script('window.SIMULATE_DRAG_ACTIVE').zero?
    end
  end

  def wait_for_vue_resource
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop until page.evaluate_script('Vue.activeResources').zero?
    end
  end
end

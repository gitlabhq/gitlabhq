require 'rails_helper'

describe 'Issue Boards', feature: true, js: true do
  let(:project)   { create(:project) }
  let(:user)      { create(:user) }
  let!(:board)    { Boards::CreateService.new(project, user).execute }

  before do
    project.team << [user, :master]
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

    it 'hides the blank state when clicking nermind button' do
      page.within('.board-blank-state') do
        click_button('Nevermind, I\'ll use my own')
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
    let(:planning)    { create(:label, project: project, name: 'Planning') }
    let(:development) { create(:label, project: project, name: 'Development') }
    let(:testing)     { create(:label, project: project, name: 'Testing') }

    let!(:list1) { create(:list, board: project.board, label: planning, position: 0) }
    let!(:list2) { create(:list, board: project.board, label: development, position: 1) }

    let!(:issue1) { create(:issue, project: project, assignee: user) }
    let!(:issue2) { create(:issue, project: project) }
    let!(:issue3) { create(:issue, project: project) }
    let!(:issue4) { create(:issue, project: project) }
    let!(:issue5) { create(:labeled_issue, project: project, labels: [planning]) }
    let!(:issue6) { create(:labeled_issue, project: project, labels: [planning, development]) }
    let!(:issue7) { create(:labeled_issue, project: project, labels: [development]) }
    let!(:issue8) { create(:closed_issue, project: project) }
    let!(:issue9) { create(:labeled_issue, project: project, labels: [testing]) }

    before do
      visit namespace_project_board_path(project.namespace, project)

      sleep 1
    end

    it 'shows lists' do
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

    it 'allows user to delete board' do
      page.within(all('.board')[1]) do
        find('.board-delete').click
      end
      expect(page).to have_selector('.board', count: 3)
    end

    context 'backlog' do
      it 'shows issues in backlog with no labels' do
        page.within(first('.board')) do
          expect(page.find('.board-header')).to have_content('5')
          expect(page).to have_selector('.card', count: 5)
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

          expect(page).to have_selector('.card', count: 2)
        end
      end

      it 'moves issue from backlog into list' do
        drag_to(list_to_index: 1)

        page.within(first('.board')) do
          expect(page.find('.board-header')).to have_content('3')
          expect(page).to have_selector('.card', count: 3)
        end

        page.within(all('.board')[1]) do
          expect(page.find('.board-header')).to have_content('3')
          expect(page).to have_selector('.card', count: 3)

          all('.card').each do |card|
            expect(card.all('.label').last).to have_content(planning.title)
          end
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
        expect(all('.board').last).to have_content(issue4.title)
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
      it 'moves between lists' do
        drag_to(list_from_index: 1, card_index: 1, list_to_index: 2)

        expect(all('.board')[1]).to have_selector('.card', count: 1)
        expect(all('.board')[2]).to have_selector('.card', count: 3)
        expect(all('.board')[2]).to have_content(issue5.title)
        expect(all('.board')[2].all('.card').last).to have_content(development.title)
      end

      it 'moves between lists' do
        drag_to(list_from_index: 2, list_to_index: 1)

        expect(all('.board')[1]).to have_selector('.card', count: 3)
        expect(all('.board')[2]).to have_selector('.card', count: 1)
        expect(all('.board')[1]).to have_content(issue7.title)
        expect(all('.board')[1].all('.card').first).to have_content(planning.title)
      end

      it 'moves from done' do
        drag_to(list_from_index: 3, list_to_index: 1)

        expect(all('.board')[1]).to have_selector('.card', count: 3)
        expect(all('.board')[1]).to have_content(issue8.title)
        expect(all('.board')[1].all('.card').first).to have_content(planning.title)
      end

      context 'issue card' do
        it 'shows assignee' do
          page.within(first('.board')) do
            expect(all('.card').last).to have_selector('.avatar')
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

        it 'moves issues from backlog into new list' do
          page.within(first('.board')) do
            expect(page.find('.board-header')).to have_content('5')
            expect(page).to have_selector('.card', count: 5)
          end

          click_button 'Create new list'

          page.within('.dropdown-menu-issues-board-new') do
            click_link testing.title
          end

          page.within(first('.board')) do
            expect(page.find('.board-header')).to have_content('4')
            expect(page).to have_selector('.card', count: 4)
          end
        end
      end
    end

    context 'filtering' do

    end
  end

  def drag_to(list_from_index: 0, card_index: 0, to_index: 0, list_to_index: 0)
    evaluate_script("simulateDrag({scrollable: document.getElementById('board-app'), from: {el: $('.board-list').eq(#{list_from_index}).get(0), index: #{card_index}}, to: {el: $('.board-list').eq(#{list_to_index}).get(0), index: #{to_index}}});")
    sleep 1
  end
end

require 'rails_helper'

describe 'Issue Boards', feature: true, js: true do
  let(:project)   { create(:project) }
  let(:user)      { create(:user) }

  before do
    project.team << [user, :master]
    login_as(user)

    visit namespace_project_board_path(project.namespace, project)
  end

  it 'shows default lists' do
    lists = all('.board')

    page.within lists.first do
      expect(page).to have_content 'Backlog'
    end

    page.within lists.last do
      expect(page).to have_content 'Done'
    end
  end

  it 'removes blank state list' do
    click_button 'Nevermind, i\'ll use my own'

    expect(page).to have_selector('.board', count: 2)
  end

  it 'can drag card to new list' do
    sleep 0.5
    lists = all('.board')
    drag_to(list_from_index: 0, list_to_index: 1)

    page.within lists[1].find('.board-list') do
      expect(page).to have_content('Test')
      expect(page).to have_selector('.card', count: 2)

      page.within first('.card .card-footer') do
        expect(page).to have_content 'Frontend'
      end
    end
  end

  it 'removes all labels from card' do
    sleep 0.5
    lists = all('.board')
    drag_to(list_from_index: 1, list_to_index: 3)

    page.within lists[3].find('.board-list') do
      expect(page).to have_content('Frontend bug')
      expect(page).to have_selector('.card', count: 2)

      page.within first('.card .card-footer') do
        expect(page).not_to have_content 'Frontend'
      end
    end

    page.within lists[1].find('.board-list') do
      expect(page).not_to have_content('Frontend bug')
      expect(page).not_to have_selector('.card')
    end
  end

  def drag_to(list_from_index: 0, card_index: 0, to_index: 0, list_to_index: 0)
    evaluate_script("simulateDrag({scrollable: document.getElementById('board-app'), from: {el: $('.board-list').eq(#{list_from_index}).get(0), index: #{card_index}}, to: {el: $('.board-list').eq(#{list_to_index}).get(0), index: #{to_index}}});")
    sleep 1
  end
end

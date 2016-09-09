require 'rails_helper'

describe 'Issue Boards', feature: true, js: true do
  include WaitForVueResource

  let(:project) { create(:empty_project, :public) }
  let(:user)    { create(:user) }
  let!(:user2)  { create(:user) }

  before do
    project.create_board
    project.board.lists.create(list_type: :backlog)
    project.board.lists.create(list_type: :done)

    project.team << [user, :master]

    login_as(user)
  end

  context 'state' do
    let(:planning)    { create(:label, project: project, name: 'Planning') }
    let!(:list1)      { create(:list, board: project.board, label: planning, position: 0) }
    let!(:issue1)     { create(:labeled_issue, :closed, project: project, labels: [planning]) }
    let!(:issue2)     { create(:labeled_issue, project: project, labels: [planning]) }

    before do
      visit namespace_project_board_path(project.namespace, project)

      wait_for_vue_resource
    end

    it 'shows all opened issues' do
      page.within('.board:nth-child(2)') do
        expect(page).to have_selector('.card', count: 1)
        expect(first('.card')).to have_content(issue2.title)
      end
    end

    it 'shows all closed issues' do
      page.within('.issues-state-filters') do
        click_link 'Closed'
      end

      wait_for_vue_resource

      page.within('.board:nth-child(2)') do
        expect(page).to have_selector('.card', count: 1)
        expect(first('.card')).to have_content(issue1.title)
      end
    end

    it 'shows all issues' do
      page.within('.issues-state-filters') do
        click_link 'All'
      end

      wait_for_vue_resource

      page.within('.board:nth-child(2)') do
        expect(page).to have_selector('.card', count: 2)
      end
    end
  end
end

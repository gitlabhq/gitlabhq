require 'rails_helper'

describe 'Multiple Issue Boards', :feature, :js do
  include WaitForAjax
  include WaitForVueResource

  let(:user) { create(:user) }
  let(:project) { create(:empty_project, :public) }
  let!(:milestone) { create(:milestone, project: project) }
  let!(:issue) { create(:closed_issue, project: project) }
  let!(:issue_milestone) { create(:closed_issue, project: project, milestone: milestone) }

  before do
    project.team << [user, :master]

    login_as(user)
  end

  context 'new board' do
    before do
      visit namespace_project_boards_path(project.namespace, project)
    end

    it 'creates board with milestone' do
      create_board_with_milestone

      click_link 'test'

      expect(find('.js-milestone-select')).to have_content(milestone.title)
      expect(all('.board')[1]).to have_selector('.card', count: 1)
    end
  end

  context 'update board' do
    let!(:milestone_two) { create(:milestone, project: project) }
    let!(:board) { create(:board, project: project, milestone: milestone) }

    before do
      visit namespace_project_boards_path(project.namespace, project)
    end

    it 'defaults milestone filter' do
      page.within '#js-multiple-boards-switcher' do
        find('.dropdown-menu-toggle').click

        wait_for_vue_resource

        click_link board.name
      end

      expect(find('.js-milestone-select')).to have_content(milestone.title)
      expect(all('.board')[1]).to have_selector('.card', count: 1)
    end

    it 'sets board to any milestone' do
      update_board_milestone('Any Milestone')

      expect(find('.js-milestone-select')).not_to have_content(milestone.title)
      expect(all('.board')[1]).to have_selector('.card', count: 2)
    end
  end

  def create_board_with_milestone
    page.within '#js-multiple-boards-switcher' do
      find('.dropdown-menu-toggle').click

      click_link 'Create new board'

      find('#board-new-name').set 'test'

      click_button 'Milestone'

      click_link milestone.title

      click_button 'Create'
    end
  end

  def update_board_milestone(milestone_title)
    page.within '#js-multiple-boards-switcher' do
      find('.dropdown-menu-toggle').click

      click_link 'Edit board milestone'

      click_link milestone_title

      click_button 'Save'
    end
  end
end

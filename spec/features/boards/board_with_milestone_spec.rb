require 'rails_helper'

describe 'Board with milestone', :feature, :js do
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

      expect(find('.tokens-container')).to have_content(milestone.title)
      wait_for_vue_resource

      find('.card', match: :first)

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

      expect(find('.tokens-container')).to have_content(milestone.title)

      find('.card', match: :first)

      expect(all('.board')[1]).to have_selector('.card', count: 1)
    end

    it 'sets board to any milestone' do
      update_board_milestone('Any Milestone')

      expect(page).not_to have_css('.js-visual-token')
      expect(find('.tokens-container')).not_to have_content(milestone.title)

      find('.card', match: :first)

      expect(page).to have_selector('.board', count: 2)
      expect(all('.board')[1]).to have_selector('.card', count: 2)
    end

    it 'sets board to upcoming milestone' do
      update_board_milestone('Upcoming')

      expect(find('.tokens-container')).not_to have_content(milestone.title)

      find('.board', match: :first)

      expect(all('.board')[1]).to have_selector('.card', count: 0)
    end

    it 'does not allow milestone in filter to be editted' do
      find('.filtered-search').native.send_keys(:backspace)

      page.within('.tokens-container') do
        expect(page).to have_selector('.value')
      end
    end

    it 'does not render milestone in hint dropdown' do
      find('.filtered-search').click

      page.within('#js-dropdown-hint') do
        expect(page).not_to have_button('Milestone')
      end
    end
  end

  context 'removing issue from board' do
    let(:label) { create(:label, project: project) }
    let!(:issue) { create(:labeled_issue, project: project, labels: [label], milestone: milestone) }
    let!(:board) { create(:board, project: project, milestone: milestone) }
    let!(:list) { create(:list, board: board, label: label, position: 0) }

    before do
      visit namespace_project_boards_path(project.namespace, project)
    end

    it 'removes issues milestone when removing from the board' do
      wait_for_vue_resource

      first('.card').click

      click_button('Remove from board')

      visit namespace_project_issue_path(project.namespace, project, issue)

      expect(page).to have_content('removed milestone')

      page.within('.milestone.block') do
        expect(page).to have_content('None')
      end
    end
  end

  context 'new issues' do
    let(:label) { create(:label, project: project) }
    let!(:list1) { create(:list, board: board, label: label, position: 0) }
    let!(:board) { create(:board, project: project, milestone: milestone) }
    let!(:issue) { create(:issue, project: project) }

    before do
      visit namespace_project_boards_path(project.namespace, project)
    end

    it 'creates new issue with boards milestone' do
      wait_for_vue_resource

      page.within(first('.board')) do
        find('.btn-default').click

        find('.form-control').set('testing new issue with milestone')

        click_button('Submit issue')

        wait_for_vue_resource

        click_link('testing new issue with milestone')
      end

      expect(page).to have_content(milestone.title)
    end

    it 'updates issue with milestone from add issues modal' do
      wait_for_vue_resource

      click_button 'Add issues'

      page.within('.add-issues-modal') do
        card = find('.card', :first)
        expect(page).to have_selector('.card', count: 1)

        card.click

        click_button 'Add 1 issue'
      end

      click_link(issue.title)

      expect(page).to have_content(milestone.title)
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

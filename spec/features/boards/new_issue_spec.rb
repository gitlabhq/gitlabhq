require 'rails_helper'

describe 'Issue Boards new issue', feature: true, js: true do
  include WaitForAjax
  include WaitForVueResource

  let(:project) { create(:project_with_board, :public) }
  let(:user)    { create(:user) }

  context 'authorized user' do
    before do
      project.team << [user, :master]

      login_as(user)

      visit namespace_project_board_path(project.namespace, project)
      wait_for_vue_resource

      expect(page).to have_selector('.board', count: 3)
    end

    it 'displays new issue button' do
      expect(page).to have_selector('.board-issue-count-holder .btn', count: 1)
    end

    it 'does not display new issue button in done list' do
      page.within('.board:nth-child(3)') do
        expect(page).not_to have_selector('.board-issue-count-holder .btn')
      end
    end

    it 'shows form when clicking button' do
      page.within(first('.board')) do
        find('.board-issue-count-holder .btn').click

        expect(page).to have_selector('.board-new-issue-form')
      end
    end

    it 'hides form when clicking cancel' do
      page.within(first('.board')) do
        find('.board-issue-count-holder .btn').click

        expect(page).to have_selector('.board-new-issue-form')

        click_button 'Cancel'

        expect(page).to have_selector('.board-new-issue-form', visible: false)
      end
    end

    it 'creates new issue' do
      page.within(first('.board')) do
        find('.board-issue-count-holder .btn').click
      end

      page.within(first('.board-new-issue-form')) do
        find('.form-control').set('bug')
        click_button 'Submit issue'
      end

      wait_for_vue_resource

      page.within(first('.board .board-issue-count')) do
        expect(page).to have_content('1')
      end
    end
  end

  context 'unauthorized user' do
    before do
      visit namespace_project_board_path(project.namespace, project)
      wait_for_vue_resource
    end

    it 'does not display new issue button' do
      expect(page).to have_selector('.board-issue-count-holder .btn', count: 0)
    end
  end
end

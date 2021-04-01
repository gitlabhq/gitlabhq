# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issue Boards new issue', :js do
  let_it_be(:project)      { create(:project, :public) }
  let_it_be(:board)        { create(:board, project: project) }
  let_it_be(:backlog_list) { create(:backlog_list, board: board) }
  let_it_be(:label)        { create(:label, project: project, name: 'Label 1') }
  let_it_be(:list)         { create(:list, board: board, label: label, position: 0) }
  let_it_be(:user)         { create(:user) }

  context 'authorized user' do
    before do
      project.add_maintainer(user)

      sign_in(user)

      visit project_board_path(project, board)

      wait_for_requests

      expect(page).to have_selector('.board', count: 3)
    end

    it 'displays new issue button' do
      expect(first('.board')).to have_selector('.issue-count-badge-add-button', count: 1)
    end

    it 'does not display new issue button in closed list' do
      page.within('.board:nth-child(3)') do
        expect(page).not_to have_selector('.issue-count-badge-add-button')
      end
    end

    it 'shows form when clicking button' do
      page.within(first('.board')) do
        find('.issue-count-badge-add-button').click

        expect(page).to have_selector('.board-new-issue-form')
      end
    end

    it 'hides form when clicking cancel' do
      page.within(first('.board')) do
        find('.issue-count-badge-add-button').click

        expect(page).to have_selector('.board-new-issue-form')

        click_button 'Cancel'

        expect(page).not_to have_selector('.board-new-issue-form')
      end
    end

    it 'creates new issue' do
      page.within(first('.board')) do
        find('.issue-count-badge-add-button').click
      end

      page.within(first('.board-new-issue-form')) do
        find('.form-control').set('bug')
        click_button 'Create issue'
      end

      wait_for_requests

      page.within(first('.board .issue-count-badge-count')) do
        expect(page).to have_content('1')
      end

      page.within(first('.board-card')) do
        issue = project.issues.find_by_title('bug')

        expect(page).to have_content(issue.to_reference)
        expect(page).to have_link(issue.title, href: /#{issue_path(issue)}/)
      end
    end

    # TODO https://gitlab.com/gitlab-org/gitlab/-/issues/323446
    xit 'shows sidebar when creating new issue' do
      page.within(first('.board')) do
        find('.issue-count-badge-add-button').click
      end

      page.within(first('.board-new-issue-form')) do
        find('.form-control').set('bug')
        click_button 'Create issue'
      end

      wait_for_requests

      expect(page).to have_selector('.issue-boards-sidebar')
    end

    it 'successfuly loads labels to be added to newly created issue' do
      page.within(first('.board')) do
        find('.issue-count-badge-add-button').click
      end

      page.within(first('.board-new-issue-form')) do
        find('.form-control').set('new issue')
        click_button 'Create issue'
      end

      wait_for_requests

      page.within(first('.board')) do
        find('.board-card').click
      end

      page.within(first('.issue-boards-sidebar')) do
        find('.labels [data-testid="edit-button"]').click

        wait_for_requests

        expect(page).to have_selector('.labels-select-contents-list .dropdown-content li a')
      end
    end
  end

  context 'unauthorized user' do
    before do
      visit project_board_path(project, board)
      wait_for_requests
    end

    it 'displays new issue button in open list' do
      expect(first('.board')).to have_selector('.issue-count-badge-add-button', count: 1)
    end

    it 'does not display new issue button in label list' do
      page.within('.board:nth-child(2)') do
        expect(page).not_to have_selector('.issue-count-badge-add-button')
      end
    end
  end

  context 'group boards' do
    let_it_be(:group) { create(:group, :public) }
    let_it_be(:project) { create(:project, :public, namespace: group) }
    let_it_be(:group_board) { create(:board, group: group) }
    let_it_be(:project_label) { create(:label, project: project, name: 'label') }
    let_it_be(:list) { create(:list, board: group_board, label: project_label, position: 0) }

    context 'for unauthorized users' do
      context 'when backlog does not exist' do
        before do
          sign_in(user)
          visit group_board_path(group, group_board)
          wait_for_requests
        end

        it 'does not display new issue button in label list' do
          page.within('.board.is-draggable') do
            expect(page).not_to have_selector('.issue-count-badge-add-button')
          end
        end
      end

      context 'when backlog list already exists' do
        let!(:backlog_list) { create(:backlog_list, board: group_board) }

        before do
          sign_in(user)
          visit group_board_path(group, group_board)
          wait_for_requests
        end

        it 'displays new issue button in open list' do
          expect(first('.board')).to have_selector('.issue-count-badge-add-button', count: 1)
        end

        it 'does not display new issue button in label list' do
          page.within('.board.is-draggable') do
            expect(page).not_to have_selector('.issue-count-badge-add-button')
          end
        end
      end
    end

    context 'for authorized users' do
      it 'display new issue button in label list' do
        project = create(:project, namespace: group)
        project.add_reporter(user)

        sign_in(user)
        visit group_board_path(group, group_board)
        wait_for_requests

        page.within('.board.is-draggable') do
          expect(page).to have_selector('.issue-count-badge-add-button')
        end
      end
    end
  end
end

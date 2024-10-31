# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group Boards', feature_category: :portfolio_management do
  include DragTo
  include MobileHelpers
  include BoardHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user) }

  context 'Creates an issue', :js do
    let_it_be(:project) { create(:project_empty_repo, group: group) }

    before do
      group.add_maintainer(user)

      sign_in(user)

      visit group_boards_path(group)
    end

    it 'adds an issue to the backlog', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/458723' do
      page.within(find('.board', match: :first)) do
        issue_title = 'Create new issue'
        click_button issue_title

        wait_for_requests

        expect(find('.board-new-issue-form')).to be_visible

        fill_in 'issue_title', with: issue_title

        within_testid('project-select-dropdown') do
          find('button.gl-new-dropdown-toggle').click

          find('.gl-new-dropdown-item').click
        end

        click_button 'Create issue'

        expect(page).to have_content(issue_title)
      end
    end
  end

  context "when user is a Reporter in one of the group's projects", :js do
    let_it_be(:board) { create(:board, group: group) }

    let_it_be(:group_label1) { create(:group_label, title: "bug", group: group) }
    let_it_be(:group_label2) { create(:group_label, title: "dev", group: group) }
    let_it_be(:list1) { create(:list, board: board, label: group_label1, position: 0) }
    let_it_be(:list2) { create(:list, board: board, label: group_label2, position: 1) }

    let_it_be(:project1) { create(:project_empty_repo, :private, group: group) }
    let_it_be(:project2) { create(:project_empty_repo, :private, group: group) }
    let_it_be(:issue1) { create(:issue, title: 'issue1', project: project1, labels: [group_label2]) }
    let_it_be(:issue2) { create(:issue, title: 'issue2', project: project2) }

    before do
      project1.add_guest(user)
      project2.add_reporter(user)
      stub_feature_flags(issues_list_drawer: false)
      sign_in(user)

      inspect_requests(inject_headers: { 'X-GITLAB-DISABLE-SQL-QUERY-LIMIT' => 'https://gitlab.com/gitlab-org/gitlab/-/issues/323426' }) do
        visit group_boards_path(group)
      end
    end

    it 'allows user to move issue of project where they are a Reporter' do
      expect(all('[data-testid="board-list"]')[0]).to have_content(issue2.title)

      drag(list_from_index: 0, from_index: 0, list_to_index: 1)

      expect(all('[data-testid="board-list"]')[1]).to have_content(issue2.title)
      expect(issue2.reload.labels).to contain_exactly(group_label1)
    end

    it 'does not allow user to move issue of project where they are a Guest' do
      expect(all('[data-testid="board-list"]')[2]).to have_content(issue1.title)

      drag(list_from_index: 2, from_index: 0, list_to_index: 1)

      expect(all('[data-testid="board-list"]')[2]).to have_content(issue1.title)
      expect(issue1.reload.labels).to contain_exactly(group_label2)
      expect(issue2.reload.labels).to eq([])
    end

    it 'does not allow user to re-position lists' do
      drag(list_from_index: 1, list_to_index: 2, selector: '.board-header')

      expect(all('[data-testid="board-list"]')[1]).to have_content(group_label1.title)
      expect(all('[data-testid="board-list"]')[2]).to have_content(group_label2.title)
      expect(list1.reload.position).to eq(0)
      expect(list2.reload.position).to eq(1)
    end

    context "when user is navigating via keyboard", :js do
      it 'allows user to traverse cards forward and backward across board columns' do
        # Focus issue2 in Open list then move to issue1 in list2 and back
        click_button 'issue2'

        expect(page).to have_selector('button.board-card-button[data-col-index="0"]', focused: true)

        send_keys :right

        expect(page).to have_selector('button.board-card-button[data-col-index="2"]', focused: true)

        send_keys :left

        expect(page).to have_selector('button.board-card-button[data-col-index="0"]', focused: true)
      end
    end
  end
end

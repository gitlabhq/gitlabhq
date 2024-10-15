# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issue Boards new issue', :js, feature_category: :portfolio_management do
  let_it_be(:project)        { create(:project, :public) }
  let_it_be(:board)          { create(:board, project: project) }
  let_it_be(:label)          { create(:label, project: project, name: 'Label 1') }
  let_it_be(:list)           { create(:list, board: board, label: label, position: 0) }
  let_it_be(:user)           { create(:user) }
  let_it_be(:existing_issue) { create(:issue, project: project, title: 'other issue', relative_position: 50) }

  let(:board_list_header) { first('[data-testid="board-list-header"]') }
  let(:project_select_dropdown) { find_by_testid('project-select-dropdown') }

  context 'when issues drawer is disabled' do
    before do
      stub_feature_flags(issues_list_drawer: false)
    end

    context 'authorized user' do
      before do
        project.add_maintainer(user)

        sign_in(user)

        visit project_board_path(project, board)

        wait_for_requests

        expect(page).to have_selector('.board', count: 3)
      end

      it 'displays new issue button' do
        expect(first('.board')).to have_button('Create new issue', count: 1)
      end

      it 'does not display new issue button in closed list' do
        page.within('[data-testid="board-list"]:nth-child(3)') do
          expect(page).not_to have_button('Create new issue')
        end
      end

      it 'shows form when clicking button' do
        page.within(first('.board')) do
          click_button 'Create new issue'

          expect(page).to have_selector('.board-new-issue-form')
        end
      end

      it 'hides form when clicking cancel' do
        page.within(first('.board')) do
          click_button 'Create new issue'

          expect(page).to have_selector('.board-new-issue-form')

          click_button 'Cancel'

          expect(page).not_to have_selector('.board-new-issue-form')
        end
      end

      it 'creates new issue, places it on top of the list, and opens sidebar' do
        page.within(first('.board')) do
          click_button 'Create new issue'
        end

        page.within(first('.board-new-issue-form')) do
          find('.form-control').set('bug')
          click_button 'Create issue'
        end

        wait_for_requests

        page.within(first('.board [data-testid="issue-count-badge"]')) do
          expect(page).to have_content('2')
        end

        page.within(first('.board-card')) do
          issue = project.issues.find_by_title('bug')

          expect(issue.relative_position).to be < existing_issue.relative_position

          expect(page).to have_content(issue.to_reference)
          expect(page).to have_link(issue.title, href: /#{issue_path(issue)}/)
        end

        expect(page).to have_selector('[data-testid="issue-boards-sidebar"]')
      end

      it 'successfully loads labels to be added to newly created issue' do
        page.within(first('.board')) do
          click_button 'Create new issue'
        end

        page.within(first('.board-new-issue-form')) do
          find('.form-control').set('new issue')
          click_button 'Create issue'
        end

        wait_for_requests

        within_testid('sidebar-labels') do
          click_button 'Edit'

          wait_for_requests

          expect(page).to have_content 'Label 1'
        end
      end

      it 'allows creating an issue in newly created list' do
        click_button 'New list'
        wait_for_all_requests

        click_button 'Select a label'
        find('label', text: label.title).click
        click_button 'Add to board'

        wait_for_all_requests

        page.within('[data-testid="board-list"]:nth-child(2)') do
          click_button('Create new issue')

          page.within(first('.board-new-issue-form')) do
            find('.form-control').set('new issue')
            click_button 'Create issue'
          end

          wait_for_all_requests

          page.within('.board-card') do
            expect(page).to have_content 'new issue'
          end
        end
      end
    end

    context 'unauthorized user' do
      before do
        visit project_board_path(project, board)
        wait_for_requests
      end

      it 'does not display new issue button in open list' do
        expect(first('.board')).not_to have_button('Create new issue')
      end

      it 'does not display new issue button in label list' do
        page.within('[data-testid="board-list"]:nth-child(2)') do
          expect(page).not_to have_button('Create new issue')
        end
      end
    end

    context 'group boards' do
      let_it_be(:group) { create(:group, :public) }
      let_it_be(:project) { create(:project, namespace: group, name: "root project") }
      let_it_be(:subgroup) { create(:group, parent: group) }
      let_it_be(:subproject1) { create(:project, group: subgroup, name: "sub project1") }
      let_it_be(:subproject2) { create(:project, group: subgroup, name: "sub project2") }
      let_it_be(:group_board) { create(:board, group: group) }
      let_it_be(:project_label) { create(:label, project: project, name: 'label') }
      let_it_be(:list) { create(:list, board: group_board, label: project_label, position: 0) }

      context 'for unauthorized users' do
        before do
          visit group_board_path(group, group_board)
          wait_for_requests
        end

        context 'when backlog does not exist' do
          it 'does not display new issue button in label list' do
            page.within('[data-testid="board-list"].is-draggable') do
              expect(page).not_to have_button('Create new issue')
            end
          end
        end

        context 'when backlog list already exists' do
          it 'does not display new issue button in open list' do
            expect(first('.board')).not_to have_button('Create new issue')
          end

          it 'does not display new issue button in label list' do
            page.within('[data-testid="board-list"].is-draggable') do
              expect(page).not_to have_button('Create new issue')
            end
          end
        end
      end

      context 'for authorized users' do
        before do
          project.add_reporter(user)
          subproject1.add_reporter(user)

          sign_in(user)
          visit group_board_path(group, group_board)
          wait_for_requests
        end

        context 'when backlog does not exist' do
          before do
            group_board.lists.backlog.delete_all
          end

          it 'display new issue button in label list' do
            expect(board_list_header).to have_button('Create new issue')
          end
        end

        context 'project select dropdown' do
          before do
            page.within(board_list_header) do
              click_button 'Create new issue'
            end

            project_select_dropdown.click

            wait_for_requests
          end

          it 'lists a project which is a direct descendant of the top-level group' do
            expect(project_select_dropdown).to have_selector("li", text: "root project")
          end

          it 'lists a project that belongs to a subgroup' do
            expect(project_select_dropdown).to have_selector("li", text: "sub project1")
          end

          it "does not list projects to which user doesn't have access" do
            expect(project_select_dropdown).not_to have_selector("li", text: "sub project2")
          end
        end
      end
    end
  end
end

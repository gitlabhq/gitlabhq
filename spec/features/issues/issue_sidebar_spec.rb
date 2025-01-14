# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issue Sidebar', feature_category: :team_planning do
  include MobileHelpers
  include Features::InviteMembersModalHelpers

  # Ensure support bot user is created so creation doesn't count towards query limit
  # See https://gitlab.com/gitlab-org/gitlab/-/issues/509629
  let_it_be(:support_bot) { Users::Internal.support_bot }
  let_it_be(:group) { create(:group, :nested) }
  let_it_be(:project) { create(:project, :public, namespace: group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:label) { create(:label, project: project, name: 'Label') }
  let_it_be(:mock_date) { Date.today.at_beginning_of_month + 2.days }

  before do
    stub_incoming_email_setting(enabled: true, address: "p+%{key}@gl.ab")
  end

  context 'when signed in' do
    before do
      sign_in(user)
    end

    context 'when concerning the assignee', :js do
      let(:user2) { create(:user) }
      let(:issue2) { create(:issue, project: project, author: user2) }

      include_examples 'issuable invite members' do
        let(:issuable_path) { project_issue_path(project, issue2) }
      end

      context 'when user is a developer' do
        before do
          project.add_developer(user)
          visit_issue(project, issue2)
        end

        it 'shows author in assignee dropdown' do
          open_assignees_dropdown

          page.within '.dropdown-menu-user' do
            expect(page).to have_content(user2.name)
          end
        end

        it 'shows author when filtering assignee dropdown' do
          open_assignees_dropdown

          page.within '.dropdown-menu-user' do
            find_by_testid('user-search-input').set(user2.name)

            wait_for_requests

            expect(page).to have_content(user2.name)
          end
        end

        it 'assigns yourself' do
          click_button 'assign yourself'
          wait_for_requests

          page.within '.assignee' do
            expect(page).to have_content(user.name)
          end
        end

        it 'keeps your filtered term after filtering and dismissing the dropdown' do
          open_assignees_dropdown

          find_by_testid('user-search-input').set(user2.name)
          wait_for_requests

          page.within '.dropdown-menu-user' do
            expect(page).not_to have_content 'Unassigned'
          end

          find('.participants').click
          wait_for_requests

          open_assignees_dropdown

          page.within('.assignee') do
            expect(page.all('[data-testid="unselected-participant"]').length).to eq(1)
          end

          expect(find_by_testid('user-search-input').value).to eq(user2.name)
        end
      end
    end

    context 'as an allowed user' do
      before do
        project.add_developer(user)
        visit_issue(project, issue)
      end

      context 'for sidebar', :js do
        sidebar_selector = 'aside.right-sidebar.right-sidebar-collapsed'
        it 'changes size when the screen size is smaller' do
          # Resize the window
          resize_screen_sm
          # Make sure the sidebar is collapsed
          find(sidebar_selector)
          expect(page).to have_css(sidebar_selector)
          # Once is collapsed let's open the sidebard and reload
          open_issue_sidebar
          refresh
          find(sidebar_selector)
          expect(page).to have_css(sidebar_selector)
          # Restore the window size as it was including the sidebar
          restore_window_size
          open_issue_sidebar
        end

        it 'passes axe automated accessibility testing', :js do
          resize_screen_sm
          open_issue_sidebar
          refresh
          find(sidebar_selector)
          expect(page).to be_axe_clean.within(sidebar_selector)
        end
      end

      context 'for editing issue milestone', :js do
        it_behaves_like 'milestone sidebar widget'
      end

      context 'for editing issue due date', :js do
        it_behaves_like 'date sidebar widget'
      end

      context 'for editing issue labels', :js do
        it_behaves_like 'labels sidebar widget'
      end

      context 'for escalation status', :js do
        it 'is not available for default issue type' do
          expect(page).not_to have_selector('.block.escalation-status')
        end
      end
    end

    context 'as a guest' do
      before do
        project.add_guest(user)
        visit_issue(project, issue)
      end

      it 'does not have a option to edit labels' do
        expect(page).not_to have_selector('.block.labels .js-sidebar-dropdown-toggle')
      end
    end
  end

  context 'when not signed in' do
    context 'for sidebar', :js do
      before do
        visit_issue(project, issue)
      end

      it 'does not find issue email' do
        expect(page).not_to have_selector('[data-testid="copy-forward-email"]')
      end
    end
  end

  def visit_issue(project, issue)
    visit project_issue_path(project, issue)

    wait_for_requests
  end

  def open_issue_sidebar
    find('aside.right-sidebar.right-sidebar-collapsed .js-sidebar-toggle').click
    find('aside.right-sidebar.right-sidebar-expanded')
  end

  def open_assignees_dropdown
    page.within('.assignee') do
      click_button('Edit')
      wait_for_requests
    end
  end
end

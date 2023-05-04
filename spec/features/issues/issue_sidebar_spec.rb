# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issue Sidebar', feature_category: :team_planning do
  include MobileHelpers
  include Features::InviteMembersModalHelpers
  include CookieHelper

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
      set_cookie('new-actions-popover-viewed', 'true')
    end

    context 'when concerning the assignee', :js do
      let(:user2) { create(:user) }
      let(:issue2) { create(:issue, project: project, author: user2) }

      context 'when GraphQL assignees widget feature flag is disabled' do
        before do
          stub_feature_flags(issue_assignees_widget: false)
        end

        include_examples 'issuable invite members' do
          let(:issuable_path) { project_issue_path(project, issue2) }
        end

        context 'when user is a developer' do
          before do
            project.add_developer(user)
            visit_issue(project, issue2)

            find('.block.assignee .edit-link').click
            wait_for_requests
          end

          it 'shows author in assignee dropdown' do
            page.within '.dropdown-menu-user' do
              expect(page).to have_content(user2.name)
            end
          end

          it 'shows author when filtering assignee dropdown' do
            page.within '.dropdown-menu-user' do
              find('.dropdown-input-field').set(user2.name)

              wait_for_requests

              expect(page).to have_content(user2.name)
            end
          end

          it 'assigns yourself' do
            find('.block.assignee .dropdown-menu-toggle').click

            click_button 'assign yourself'

            wait_for_requests

            find('.block.assignee .edit-link').click

            page.within '.dropdown-menu-user' do
              expect(page.find('.dropdown-header')).to be_visible
              expect(page.find('.dropdown-menu-user-link.is-active')).to have_content(user.name)
            end
          end

          it 'keeps your filtered term after filtering and dismissing the dropdown' do
            find('.dropdown-input-field').set(user2.name)

            wait_for_requests

            page.within '.dropdown-menu-user' do
              expect(page).not_to have_content 'Unassigned'
              click_link user2.name
            end

            within '.js-right-sidebar' do
              find('.block.assignee').click(x: 0, y: 0, offset: 0)
              find('.block.assignee .edit-link').click
            end

            expect(page.all('.dropdown-menu-user li').length).to eq(6)
            expect(find('.dropdown-input-field').value).to eq('')
          end

          it 'shows label text as "Apply" when assignees are changed' do
            project.add_developer(user)
            visit_issue(project, issue2)

            find('.block.assignee .edit-link').click
            wait_for_requests

            click_on 'Unassigned'

            expect(page).to have_link('Apply')
          end
        end
      end

      context 'when GraphQL assignees widget feature flag is enabled' do
        # TODO: Move to shared examples when feature flag is removed: https://gitlab.com/gitlab-org/gitlab/-/issues/328185
        context 'when a privileged user can invite' do
          it 'shows a link for inviting members and launches invite modal' do
            project.add_maintainer(user)
            visit_issue(project, issue2)

            open_assignees_dropdown

            page.within '.dropdown-menu-user' do
              expect(page).to have_link('Invite members')

              click_link 'Invite members'
            end

            page.within invite_modal_selector do
              expect(page).to have_content("You're inviting members to the #{project.name} project")
            end
          end
        end

        context 'when user cannot invite members in assignee dropdown' do
          it 'shows author in assignee dropdown and no invite link' do
            project.add_developer(user)
            visit_issue(project, issue2)

            open_assignees_dropdown

            page.within '.dropdown-menu-user' do
              expect(page).not_to have_link('Invite members')
            end
          end
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
              find('.js-dropdown-input-field').find('input').set(user2.name)

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

            find('.js-dropdown-input-field').find('input').set(user2.name)
            wait_for_requests

            page.within '.dropdown-menu-user' do
              expect(page).not_to have_content 'Unassigned'
              click_button user2.name
            end

            find('.participants').click
            wait_for_requests

            open_assignees_dropdown

            page.within('.assignee') do
              expect(page.all('[data-testid="selected-participant"]').length).to eq(1)
            end

            expect(find('.js-dropdown-input-field').find('input').value).to eq(user2.name)
          end
        end
      end
    end

    context 'as an allowed user' do
      before do
        stub_feature_flags(moved_mr_sidebar: false)
        project.add_developer(user)
        visit_issue(project, issue)
      end

      context 'for sidebar', :js do
        it 'changes size when the screen size is smaller' do
          sidebar_selector = 'aside.right-sidebar.right-sidebar-collapsed'
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

      context 'when interacting with collapsed sidebar', :js do
        collapsed_sidebar_selector = 'aside.right-sidebar.right-sidebar-collapsed'
        expanded_sidebar_selector = 'aside.right-sidebar.right-sidebar-expanded'
        confidentiality_sidebar_block = '.block.confidentiality'
        lock_sidebar_block = '.block.lock'
        collapsed_sidebar_block_icon = '.sidebar-collapsed-icon'

        before do
          resize_screen_sm
        end

        it 'confidentiality block expands then collapses sidebar' do
          expect(page).to have_css(collapsed_sidebar_selector)

          page.within(confidentiality_sidebar_block) do
            find(collapsed_sidebar_block_icon).click
          end

          expect(page).to have_css(expanded_sidebar_selector)

          page.within(confidentiality_sidebar_block) do
            page.find('button', text: 'Cancel').click
          end

          expect(page).to have_css(collapsed_sidebar_selector)
        end

        it 'lock block expands then collapses sidebar' do
          expect(page).to have_css(collapsed_sidebar_selector)

          page.within(lock_sidebar_block) do
            find(collapsed_sidebar_block_icon).click
          end

          expect(page).to have_css(expanded_sidebar_selector)

          page.within(lock_sidebar_block) do
            page.find('button', text: 'Cancel').click
          end

          expect(page).to have_css(collapsed_sidebar_selector)
        end
      end
    end

    context 'as a guest' do
      before do
        stub_feature_flags(moved_mr_sidebar: false)
        project.add_guest(user)
        visit_issue(project, issue)
      end

      it 'does not have a option to edit labels' do
        expect(page).not_to have_selector('.block.labels .js-sidebar-dropdown-toggle')
      end

      context 'for sidebar', :js do
        it 'finds issue copy forwarding email' do
          expect(
            find('[data-testid="copy-forward-email"]').text
          ).to eq "Issue email: #{issue.creatable_note_email_address(user)}"
        end
      end

      context 'when interacting with collapsed sidebar', :js do
        collapsed_sidebar_selector = 'aside.right-sidebar.right-sidebar-collapsed'
        expanded_sidebar_selector = 'aside.right-sidebar.right-sidebar-expanded'
        lock_sidebar_block = '.block.lock'
        lock_button = '.block.lock .btn-close'
        collapsed_sidebar_block_icon = '.sidebar-collapsed-icon'

        before do
          resize_screen_sm
        end

        it 'expands then does not show the lock dialog form' do
          expect(page).to have_css(collapsed_sidebar_selector)

          page.within(lock_sidebar_block) do
            find(collapsed_sidebar_block_icon).click
          end

          expect(page).to have_css(expanded_sidebar_selector)
          expect(page).not_to have_selector(lock_button)
        end
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

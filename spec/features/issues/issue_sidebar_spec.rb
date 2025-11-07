# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issue Sidebar', :js, feature_category: :team_planning do
  include ListboxHelpers
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
    stub_feature_flags(work_item_view_for_issues: true)
    stub_incoming_email_setting(enabled: true, address: "p+%{key}@gl.ab")
  end

  context 'when signed in' do
    before do
      sign_in(user)
    end

    context 'for assignee widget' do
      let(:user2) { create(:user) }
      let(:issue2) { create(:issue, project: project, author: user2) }

      include_examples 'issuable invite members' do
        let(:issuable_path) { project_issue_path(project, issue2) }
      end

      context 'when user is a developer' do
        before do
          project.add_developer(user)
          visit project_issue_path(project, issue2)
        end

        it 'shows author in assignee dropdown and when filtering assignee dropdown, and assigns yourself' do
          within_testid('work-item-assignees') do
            click_button 'Edit'

            expect_listbox_item(user2.name)

            send_keys user2.name

            expect_listbox_item(user2.name)

            send_keys :escape
            click_button 'assign yourself'

            expect(page).to have_link(user.name)
          end
        end
      end
    end

    context 'as an allowed user' do
      before do
        project.add_developer(user)
        visit project_issue_path(project, issue)
      end

      context 'for milestone widget' do
        let_it_be(:milestone_expired) do
          create(:milestone, project: project, title: 'Foo - expired', due_date: 5.days.ago)
        end

        let_it_be(:milestone_no_duedate) do
          create(:milestone, project: project, title: 'Foo - No due date')
        end

        let_it_be(:milestone1) do
          create(:milestone, project: project, title: 'Milestone-1', due_date: 20.days.from_now)
        end

        let_it_be(:milestone2) do
          create(:milestone, project: project, title: 'Milestone-2', due_date: 15.days.from_now)
        end

        let_it_be(:milestone3) do
          create(:milestone, project: project, title: 'Milestone-3', due_date: 10.days.from_now)
        end

        it 'shows milestones list in the dropdown, with soonest due at the top and expired at the bottom' do
          within_testid('work-item-milestone') do
            click_button 'Edit'

            expect_listbox_items(['Milestone-3', 'Milestone-2', 'Milestone-1', 'Foo - No due date',
              'Foo - expired (expired)'])
          end
        end

        it 'adds and removes a milestone' do
          within_testid('work-item-milestone') do
            click_button 'Edit'
            select_listbox_item(milestone1.title)

            expect(page).to have_link(milestone1.title)

            click_button 'Edit'
            click_button 'Clear'

            expect(page).to have_text('None')
            expect(page).not_to have_link(milestone1.title)
          end
        end
      end

      context 'for dates widget' do
        it 'ensures the due date is persisted after a reload', :sidekiq_inline do
          # Issues with empty dates sources were not persisting the due date on edit
          # https://gitlab.com/gitlab-org/gitlab/-/issues/517311
          create(:work_items_dates_source, issue_id: issue.id)

          new_date = Time.zone.today

          wait_for_all_requests

          within_testid('work-item-due-dates') do
            click_button 'Edit'
            find_field('Due').click
          end
          within('.pika-lendar') do
            click_button new_date.day.to_s
          end
          within_testid('work-item-due-dates') do
            click_button 'Apply'

            expect(page).to have_text(new_date.strftime('%b %-d, %Y'))
          end

          visit project_issue_path(project, issue)

          within_testid('work-item-due-dates') do
            expect(page).to have_text(new_date.strftime('%b %-d, %Y'))
          end
        end
      end

      context 'for labels widget' do
        let_it_be(:development) { create(:group_label, group: group, name: 'Development') }
        let_it_be(:stretch) { create(:label, project: project, name: 'Stretch') }
        let_it_be(:xss_label) do
          create(:label, project: project, title: '<script>alert("xss");</script>')
        end

        it 'shows labels list in the dropdown' do
          within_testid('work-item-labels') do
            click_button 'Edit'

            expect_listbox_item('<script>alert("xss");</script>')
            expect_listbox_item('Development')
            expect_listbox_item('Label')
            expect_listbox_item('Stretch')
          end
        end

        it 'adds and removes a label' do
          within_testid('work-item-labels') do
            click_button 'Edit'
            select_listbox_item(stretch.name)
            click_button 'Apply'

            expect(page).to have_link(stretch.name)

            click_button 'Edit'
            click_button 'Clear'

            expect(page).to have_text('None')
            expect(page).not_to have_link(stretch.name)
          end
        end

        it 'creates new label' do
          within_testid('work-item-labels') do
            click_button 'Edit'
            click_button 'Create project label'

            expect(page).to have_text 'Create label'

            fill_in 'Label name', with: 'wontfix'
            click_link 'Magenta-pink'
            click_button 'Create'

            expect_listbox_item('wontfix')

            click_button 'Apply'

            expect(page).to have_link('wontfix')
          end
        end

        it 'shows error message if creating a label with existing title' do
          within_testid('work-item-labels') do
            click_button 'Edit'
            click_button 'Create project label'
            fill_in 'Label name', with: stretch.title
            click_link 'Magenta-pink'
            click_button 'Create'

            expect(page).to have_css '.gl-alert', text: 'Title has already been taken'
          end
        end
      end

      context 'for escalation status' do
        it 'is not available for default issue type' do
          expect(page).not_to have_selector('.block.escalation-status')
        end
      end
    end

    context 'as a guest' do
      before do
        project.add_guest(user)
        visit project_issue_path(project, issue)
      end

      it 'does not have a option to edit widgets' do
        within_testid('work-item-overview-right-sidebar') do
          expect(page).not_to have_selector('.block.labels .js-sidebar-dropdown-toggle')
        end
      end
    end
  end

  def open_assignees_dropdown
    within_testid('work-item-assignees') do
      click_button('Edit')
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Work item', :js, feature_category: :team_planning do
  before do
    stub_feature_flags(notifications_todos_buttons: false)
  end

  include ListboxHelpers

  let_it_be_with_reload(:user) { create(:user) }
  let_it_be_with_reload(:user2) { create(:user, name: 'John') }

  let_it_be(:project) { create(:project, :public) }
  let_it_be(:work_item) { create(:work_item, project: project) }
  let_it_be(:task) { create(:work_item, :task, project: project) }
  let_it_be(:emoji_upvote) { create(:award_emoji, :upvote, awardable: work_item, user: user2) }
  let_it_be(:milestone) { create(:milestone, project: project) }
  let_it_be(:milestones) { create_list(:milestone, 25, project: project) }
  let_it_be(:note) { create(:note, noteable: work_item, project: work_item.project) }
  let(:work_items_path) { project_work_item_path(project, work_item.iid) }
  let_it_be(:label) { create(:label, project: work_item.project, title: "testing-label") }

  context 'for signed in user' do
    before do
      stub_feature_flags(notifications_todos_buttons: false)
      stub_const("AutocompleteSources::ExpiresIn::AUTOCOMPLETE_EXPIRES_IN", 0)
      project.add_developer(user)
      sign_in(user)
      visit work_items_path
    end

    it 'shows project issues link in breadcrumbs' do
      within_testid('breadcrumb-links') do
        expect(page).to have_link(project.name, href: project_path(project))
        expect(page).to have_link('Issues', href: project_issues_path(project))
      end
    end

    it 'uses IID path in breadcrumbs' do
      within_testid('breadcrumb-links') do
        expect(find('li:last-of-type')).to have_link("##{work_item.iid}", href: work_items_path)
      end
    end

    it 'actions dropdown is displayed' do
      expect(page).to have_button _('More actions')
    end

    context 'when work_items_beta is enabled' do
      before do
        stub_feature_flags(work_items_beta: true)
        stub_feature_flags(notifications_todos_buttons: false)

        page.refresh
        wait_for_all_requests
      end

      it 'reassigns to another user',
        quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/413074' do
        within_testid('work-item-assignees') do
          click_button 'Edit'
        end

        select_listbox_item(user.username)

        wait_for_requests

        within_testid('work-item-assignees') do
          click_button 'Edit'
        end

        select_listbox_item(user2.username)

        wait_for_requests

        expect(work_item.reload.assignees).to include(user2)
      end
    end

    it_behaves_like 'work items title'
    it_behaves_like 'work items toggle status button'
    it_behaves_like 'work items assignees'
    it_behaves_like 'work items labels'
    it_behaves_like 'work items comments', :issue
    it_behaves_like 'work items description'
    it_behaves_like 'work items milestone'
    it_behaves_like 'work items notifications'
    it_behaves_like 'work items todos'
    it_behaves_like 'work items award emoji'
    it_behaves_like 'work items time tracking'
  end

  context 'for signed in owner' do
    before do
      project.add_owner(user)
      sign_in(user)
      visit work_items_path
    end

    it_behaves_like 'work items invite members'
  end

  context 'for guest users' do
    before do
      project.add_guest(user)
      sign_in(user)
      visit work_items_path
    end

    it_behaves_like 'work items comment actions for guest users'
  end

  context 'when item is a task' do
    before do
      project.add_developer(user)

      sign_in(user)

      visit project_work_item_path(project, task.iid)
    end

    it_behaves_like 'work items parent', :issue
  end

  context 'for user not signed in' do
    before do
      visit work_items_path
    end

    it 'todos action is not displayed' do
      expect(page).not_to have_button s_('WorkItem|Add a to do')
    end

    it 'award button is disabled and add reaction is not displayed' do
      expect(page).not_to have_button _('Add reaction')
      expect(page).to have_selector('[data-testid="award-button"].disabled')
    end

    context 'when work_items_beta is enabled' do
      before do
        stub_feature_flags(work_items_beta: true)

        page.refresh
        wait_for_all_requests
      end

      it 'hides the assignees edit button' do
        within_testid('work-item-assignees') do
          expect(page).not_to have_button('Edit')
        end
      end

      it 'hides the labels edit button' do
        within_testid('work-item-labels') do
          expect(page).not_to have_button('Edit')
        end
      end
    end
  end
end

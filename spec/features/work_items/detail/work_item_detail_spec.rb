# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Work item detail', :js, feature_category: :team_planning do
  include ListboxHelpers

  let_it_be_with_reload(:user) { create(:user) }
  let_it_be_with_reload(:user2) { create(:user, name: 'John') }

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :public, :repository, group: group) }
  let_it_be(:label) { create(:label, project: project, title: "testing-label") }
  let_it_be(:label2) { create(:label, project: project, title: "another-label") }
  let_it_be(:work_item) { create(:work_item, project: project, labels: [label]) }
  let_it_be(:task) { create(:work_item, :task, project: project) }
  let_it_be(:emoji_upvote) { create(:award_emoji, :upvote, awardable: work_item, user: user2) }
  let_it_be(:milestone) { create(:milestone, project: project) }
  let_it_be(:milestones) { create_list(:milestone, 10, project: project) }
  let_it_be(:note) { create(:note, noteable: work_item, project: work_item.project) }
  let_it_be(:contact) { create(:contact, group: group) }
  let(:contact_name) { "#{contact.first_name} #{contact.last_name}" }
  let(:list_path) { project_issues_path(project) }
  let(:work_items_path) { project_work_item_path(project, work_item.iid) }

  before do
    # TODO: When removing the feature flag,
    # we won't need the tests for the issues listing page, since we'll be using
    # the work items listing page.
    stub_feature_flags(work_item_planning_view: false)
  end

  shared_examples 'change type action is not displayed' do
    it 'change type action is not displayed' do
      click_button _('More actions'), match: :first

      expect(find_by_testid('work-item-actions-dropdown')).not_to have_button(s_('WorkItem|Change type'))
    end
  end

  context 'for signed in user' do
    let(:linked_item) { task }

    before_all do
      stub_feature_flags(comment_temperature: false)
      group.add_developer(user)
    end

    before do
      stub_feature_flags(notifications_todos_buttons: false, work_item_planning_view: false)
      stub_const("AutocompleteSources::ExpiresIn::AUTOCOMPLETE_EXPIRES_IN", 0)
      sign_in(user)
      visit work_items_path
    end

    it 'shows breadcrumb links', :aggregate_failures do
      within_testid('breadcrumb-links') do
        expect(page).to have_link(project.name, href: project_path(project))
        expect(page).to have_link('Issues', href: list_path)
        expect(find('nav:last-of-type li:last-of-type')).to have_link("##{work_item.iid}", href: work_items_path)
      end
    end

    it_behaves_like 'work items title'
    it_behaves_like 'work items description'
    it_behaves_like 'work items award emoji'
    it_behaves_like 'work items linked items'
    it_behaves_like 'work items comments', :issue
    it_behaves_like 'work items toggle status button'

    it_behaves_like 'work items todos'
    it_behaves_like 'work items lock discussion', 'issue'
    it_behaves_like 'work items confidentiality'
    it_behaves_like 'work items notifications'

    it_behaves_like 'work items assignees'
    it_behaves_like 'work items labels', 'project'
    it_behaves_like 'work items milestone'
    it_behaves_like 'work items time tracking'
    it_behaves_like 'work items crm contacts'
  end

  context 'when item is a task' do
    before_all do
      project.add_developer(user)
    end

    before do
      sign_in(user)
      visit project_work_item_path(project, task.iid)
    end

    it_behaves_like 'work items parent', :issue
    it_behaves_like 'work items change type', 'Issue', '[data-testid="issue-type-issue-icon"]'
  end

  context 'for signed in admin' do
    let_it_be(:admin) { create(:admin) }

    context 'with akismet integration' do
      let_it_be(:user_agent_detail) { create(:user_agent_detail, subject: work_item) }

      before_all do
        project.add_maintainer(admin)
      end

      before do
        stub_application_setting(akismet_enabled: true)
        sign_in(admin)
        visit work_items_path
      end

      it_behaves_like 'work items submit as spam'
    end
  end

  context 'for signed in owner' do
    before_all do
      project.add_owner(user)
    end

    before do
      sign_in(user)
      visit work_items_path
    end

    it_behaves_like 'work items invite members'
  end

  context 'for guest users' do
    before_all do
      project.add_guest(user)
    end

    context 'for work item authored by guest user' do
      let_it_be(:key_result) { create(:work_item, :key_result, author: user, project: project) }
      let_it_be(:note) { create(:note, noteable: key_result, project: key_result.project) }

      before do
        sign_in(user)
        visit project_work_item_path(project, key_result.iid)
      end

      it_behaves_like 'authored work item guest user permissions'
    end

    context 'for work item not authored by guest user' do
      before do
        sign_in(user)
        visit work_items_path
      end

      it_behaves_like 'non-authored work item guest user permissions'
    end
  end

  context 'for user not signed in' do
    before do
      visit work_items_path
      wait_for_all_requests
    end

    it 'todos action is not displayed' do
      expect(page).not_to have_button s_('WorkItem|Add a to-do item')
    end

    it 'award button is disabled and add reaction is not displayed' do
      expect(page).not_to have_button _('Add reaction')
      expect(page).to have_selector('[data-testid="award-button"].disabled')
    end

    it 'renders note' do
      wait_for_all_requests

      expect(page).to have_content(note.note)
    end

    it_behaves_like 'change type action is not displayed'
  end

  context 'for development widget' do
    let_it_be(:merge_request) do
      create(
        :merge_request,
        source_project: project,
        source_branch: "#{work_item.iid}-feature",
        target_project: project,
        target_branch: "master",
        title: "Related Merge Request",
        description: "Merge request description, fixes ##{work_item.iid}"
      )
    end

    before_all do
      project.add_developer(user)
    end

    context 'for user signed in' do
      before do
        sign_in(user)
        visit work_items_path

        wait_for_all_requests
      end

      it 'shows development widget with merge request' do
        within_testid('work-item-development') do
          expect(page.find('li a')[:href]).to include(merge_request_path(merge_request))
        end
      end
    end

    context 'for user not signed in' do
      before do
        visit work_items_path
        wait_for_all_requests
      end

      it 'shows development widget with merge request' do
        within_testid('work-item-development') do
          expect(page.find('li a')[:href]).to include(merge_request_path(merge_request))
        end
      end
    end
  end
end

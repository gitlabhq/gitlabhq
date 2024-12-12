# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Work item detail', :js, feature_category: :team_planning do
  include ListboxHelpers

  let_it_be_with_reload(:user) { create(:user) }
  let_it_be_with_reload(:user2) { create(:user, name: 'John') }

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :public, group: group) }
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

  context 'for signed in user' do
    let(:linked_item) { task }

    before_all do
      group.add_developer(user)
    end

    before do
      stub_feature_flags(notifications_todos_buttons: false)
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

    before do
      sign_in(user)
      visit work_items_path
    end

    it_behaves_like 'work items comment actions for guest users'
  end

  context 'for user not signed in' do
    before do
      visit work_items_path
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
  end
end

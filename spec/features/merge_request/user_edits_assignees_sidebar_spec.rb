# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User edits assignees sidebar', :js, feature_category: :code_review_workflow do
  include Features::InviteMembersModalHelpers

  let(:owner) { create(:user) }
  let(:shared_into_ancestor_user) { create(:user) }
  let(:invited_group) { create(:group) { |group| group.add_maintainer(shared_into_ancestor_user) } }
  let(:parent_group) do
    create(:group) { |group| create(:group_group_link, shared_group: group, shared_with_group: invited_group) }
  end

  let(:project) do
    create(:project, :public, :repository, group: parent_group) { |project| project.add_owner(owner) }
  end

  let(:protected_branch) { create(:protected_branch, :maintainers_can_push, name: 'master', project: project) }
  let(:merge_request) { create(:merge_request, :simple, source_project: project, target_branch: protected_branch.name) }

  let(:users_find_limit) { 5 }

  # Insert more than limit so that response doesn't include assigned user
  let(:project_developers) { Array.new(users_find_limit + 1) { create(:user, developer_of: project) } }
  let(:project_maintainers) { Array.new(users_find_limit + 1) { create(:user, maintainer_of: project) } }

  # DOM finders to simplify and improve readability
  let(:sidebar_assignee_block) { page.find('.js-issuable-sidebar .assignee') }
  let(:sidebar_assignee_avatar_link) do
    sidebar_assignee_block.find_all('a').find { |a| a['href'].include? assignee.username }
  end

  let(:sidebar_assignee_tooltip) { sidebar_assignee_avatar_link['title'] || '' }
  let(:sidebar_assignee_merge_ability) { sidebar_assignee_avatar_link['data-cannot-merge'] || '' }

  let(:sidebar_assignee_dropdown_item) { sidebar_assignee_block.find(".dropdown-item", text: assignee.username) }
  let(:sidebar_assignee_dropdown_tooltip) { sidebar_assignee_dropdown_item['title'] }

  context 'when user is an owner' do
    before do
      stub_const('Autocomplete::UsersFinder::LIMIT', users_find_limit)

      sign_in(owner)

      merge_request.assignees << assignee

      visit project_merge_request_path(project, merge_request)

      wait_for_requests
    end

    shared_examples 'when assigned' do |expected_tooltip: '', expected_cannot_merge: ''|
      it 'shows assignee name' do
        expect(sidebar_assignee_block).to have_text(assignee.name)
      end

      it "sets data-cannot-merge to '#{expected_cannot_merge}'" do
        expect(sidebar_assignee_merge_ability).to eql(expected_cannot_merge)
      end

      context 'when edit is clicked' do
        before do
          open_assignees_dropdown
        end

        it "shows assignee tooltip '#{expected_tooltip}" do
          expect(sidebar_assignee_dropdown_tooltip).to eql(expected_tooltip)
        end
      end
    end

    context 'when assigned to maintainer' do
      let(:assignee) { project_maintainers.last }

      it_behaves_like 'when assigned', expected_tooltip: ''
    end

    context 'when assigned to developer' do
      let(:assignee) { project_developers.last }

      it_behaves_like 'when assigned', expected_tooltip: 'Cannot merge', expected_cannot_merge: 'true'
    end
  end

  context 'with members shared into ancestors of the project' do
    before do
      sign_in(owner)

      visit project_merge_request_path(project, merge_request)
      wait_for_requests

      open_assignees_dropdown
    end

    it 'contains the members shared into ancestors of the projects' do
      page.within '.dropdown-menu-user' do
        expect(page).to have_content shared_into_ancestor_user.name
      end
    end
  end

  context 'with invite members considerations' do
    let_it_be(:user) { create(:user) }

    before do
      sign_in(user)
    end

    include_examples 'issuable invite members' do
      let(:issuable_path) { project_merge_request_path(project, merge_request) }
    end
  end

  def open_assignees_dropdown
    page.within('.assignee') do
      click_button('Edit')
      wait_for_requests
    end
  end
end

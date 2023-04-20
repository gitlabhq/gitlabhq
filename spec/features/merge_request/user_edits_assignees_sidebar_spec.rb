# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User edits assignees sidebar', :js, feature_category: :code_review_workflow do
  include Features::InviteMembersModalHelpers

  let(:project) { create(:project, :public, :repository) }
  let(:protected_branch) { create(:protected_branch, :maintainers_can_push, name: 'master', project: project) }
  let(:merge_request) { create(:merge_request, :simple, source_project: project, target_branch: protected_branch.name) }

  let(:users_find_limit) { 5 }

  # Insert more than limit so that response doesn't include assigned user
  let(:project_developers) { Array.new(users_find_limit + 1) { create(:user).tap { |u| project.add_developer(u) } } }
  let(:project_maintainers) { Array.new(users_find_limit + 1) { create(:user).tap { |u| project.add_maintainer(u) } } }

  # DOM finders to simplify and improve readability
  let(:sidebar_assignee_block) { page.find('.js-issuable-sidebar .assignee') }
  let(:sidebar_assignee_avatar_link) do
    sidebar_assignee_block.find_all('a').find { |a| a['href'].include? assignee.username }
  end

  let(:sidebar_assignee_tooltip) { sidebar_assignee_avatar_link['title'] || '' }

  context 'when GraphQL assignees widget feature flag is disabled' do
    let(:sidebar_assignee_dropdown_item) do
      sidebar_assignee_block.find(".dropdown-menu li[data-user-id=\"#{assignee.id}\"]")
    end

    let(:sidebar_assignee_dropdown_tooltip) { sidebar_assignee_dropdown_item.find('a')['data-title'] || '' }

    before do
      stub_feature_flags(issue_assignees_widget: false)
    end

    context 'when user is an owner' do
      before do
        stub_const('Autocomplete::UsersFinder::LIMIT', users_find_limit)

        sign_in(project.first_owner)

        merge_request.assignees << assignee

        visit project_merge_request_path(project, merge_request)

        wait_for_requests
      end

      shared_examples 'when assigned' do |expected_tooltip: ''|
        it 'shows assignee name' do
          expect(sidebar_assignee_block).to have_text(assignee.name)
        end

        it "shows assignee tooltip '#{expected_tooltip}'" do
          expect(sidebar_assignee_tooltip).to eql(expected_tooltip)
        end

        context 'when edit is clicked' do
          before do
            sidebar_assignee_block.click_link('Edit')

            wait_for_requests
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

        it_behaves_like 'when assigned', expected_tooltip: 'Cannot merge'
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
  end

  context 'when GraphQL assignees widget feature flag is enabled' do
    let(:sidebar_assignee_dropdown_item) { sidebar_assignee_block.find(".dropdown-item", text: assignee.username) }
    let(:sidebar_assignee_dropdown_tooltip) { sidebar_assignee_dropdown_item['title'] }

    context 'when user is an owner' do
      before do
        stub_const('Autocomplete::UsersFinder::LIMIT', users_find_limit)

        sign_in(project.first_owner)

        merge_request.assignees << assignee

        visit project_merge_request_path(project, merge_request)

        wait_for_requests
      end

      shared_examples 'when assigned' do |expected_tooltip: ''|
        it 'shows assignee name' do
          expect(sidebar_assignee_block).to have_text(assignee.name)
        end

        it "shows assignee tooltip '#{expected_tooltip}'" do
          expect(sidebar_assignee_tooltip).to eql(expected_tooltip)
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

        it_behaves_like 'when assigned', expected_tooltip: 'Cannot merge'
      end
    end

    context 'with invite members considerations' do
      let_it_be(:user) { create(:user) }

      before do
        sign_in(user)
      end

      # TODO: Move to shared examples when feature flag is removed: https://gitlab.com/gitlab-org/gitlab/-/issues/328185
      context 'when a privileged user can invite' do
        it 'shows a link for inviting members and launches invite modal' do
          project.add_maintainer(user)
          visit project_merge_request_path(project, merge_request)

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
          visit project_merge_request_path(project, merge_request)

          open_assignees_dropdown

          page.within '.dropdown-menu-user' do
            expect(page).not_to have_link('Invite members')
          end
        end
      end
    end
  end

  def open_assignees_dropdown
    page.within('.assignee') do
      click_button('Edit')
      wait_for_requests
    end
  end
end

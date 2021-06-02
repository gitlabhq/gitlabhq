# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project > Members > Invite group', :js do
  include Select2Helper
  include ActionView::Helpers::DateHelper
  include Spec::Support::Helpers::Features::MembersHelpers
  include Spec::Support::Helpers::Features::InviteMembersModalHelper

  let(:maintainer) { create(:user) }

  using RSpec::Parameterized::TableSyntax

  where(:invite_members_group_modal_enabled, :expected_invite_group_selector) do
    true  | 'button[data-qa-selector="invite_a_group_button"]'
    false | '#invite-group-tab'
  end

  with_them do
    before do
      stub_feature_flags(invite_members_group_modal: invite_members_group_modal_enabled)
    end

    it 'displays either the invite group button or the form with tabs based on the feature flag' do
      project = create(:project, namespace: create(:group))

      project.add_maintainer(maintainer)
      sign_in(maintainer)

      visit project_project_members_path(project)

      expect(page).to have_selector(expected_invite_group_selector)
    end

    it 'does not display either the form or the button when visiting the page not signed in' do
      project = create(:project, namespace: create(:group))

      visit project_project_members_path(project)

      expect(page).not_to have_selector(expected_invite_group_selector)
    end
  end

  describe 'Share with group lock' do
    let(:invite_group_selector) { 'button[data-qa-selector="invite_a_group_button"]' }

    shared_examples 'the project can be shared with groups' do
      it 'the "Invite a group" button exists' do
        visit project_project_members_path(project)
        expect(page).to have_selector(invite_group_selector)
      end
    end

    shared_examples 'the project cannot be shared with groups' do
      it 'the "Invite a group" button does not exist' do
        visit project_project_members_path(project)
        expect(page).not_to have_selector(invite_group_selector)
      end
    end

    context 'for a project in a root group' do
      let!(:group_to_share_with) { create(:group) }
      let(:project) { create(:project, namespace: create(:group)) }

      before do
        project.add_maintainer(maintainer)
        group_to_share_with.add_guest(maintainer)
        sign_in(maintainer)
      end

      context 'when the group has "Share with group lock" disabled' do
        it_behaves_like 'the project can be shared with groups'

        it 'the project can be shared with another group when the feature flag invite_members_group_modal is disabled' do
          stub_feature_flags(invite_members_group_modal: false)

          visit project_project_members_path(project)

          expect(page).not_to have_link 'Groups'

          click_on 'invite-group-tab'

          select2 group_to_share_with.id, from: '#link_group_id'
          page.find('body').click
          find('.btn-confirm').click

          click_link 'Groups'

          expect(members_table).to have_content(group_to_share_with.name)
        end

        it 'the project can be shared with another group when the feature flag invite_members_group_modal is enabled' do
          stub_feature_flags(invite_members_group_modal: true)

          visit project_project_members_path(project)

          expect(page).not_to have_link 'Groups'

          invite_group(group_to_share_with.name)

          visit project_project_members_path(project)

          click_link 'Groups'

          expect(members_table).to have_content(group_to_share_with.name)
        end
      end

      context 'when the group has "Share with group lock" enabled' do
        before do
          project.namespace.update_column(:share_with_group_lock, true)
        end

        it_behaves_like 'the project cannot be shared with groups'
      end
    end

    context 'for a project in a subgroup' do
      let!(:group_to_share_with) { create(:group) }
      let(:root_group) { create(:group) }
      let(:subgroup) { create(:group, parent: root_group) }
      let(:project) { create(:project, namespace: subgroup) }

      before do
        project.add_maintainer(maintainer)
        sign_in(maintainer)
      end

      context 'when the root_group has "Share with group lock" disabled' do
        context 'when the subgroup has "Share with group lock" disabled' do
          it_behaves_like 'the project can be shared with groups'
        end

        context 'when the subgroup has "Share with group lock" enabled' do
          before do
            subgroup.update_column(:share_with_group_lock, true)
          end

          it_behaves_like 'the project cannot be shared with groups'
        end
      end

      context 'when the root_group has "Share with group lock" enabled' do
        before do
          root_group.update_column(:share_with_group_lock, true)
        end

        context 'when the subgroup has "Share with group lock" disabled (parent overridden)' do
          it_behaves_like 'the project can be shared with groups'
        end

        context 'when the subgroup has "Share with group lock" enabled' do
          before do
            subgroup.update_column(:share_with_group_lock, true)
          end

          it_behaves_like 'the project cannot be shared with groups'
        end
      end
    end
  end

  describe 'setting an expiration date for a group link' do
    let(:project) { create(:project) }
    let!(:group) { create(:group) }

    around do |example|
      freeze_time { example.run }
    end

    def setup
      project.add_maintainer(maintainer)
      group.add_guest(maintainer)
      sign_in(maintainer)

      visit project_project_members_path(project)

      invite_group(group.name, role: 'Guest', expires_at: 5.days.from_now)
    end

    it 'the group link shows the expiration time with a warning class' do
      setup
      click_link 'Groups'

      expect(find_group_row(group)).to have_content(/in \d days/)
      expect(find_group_row(group)).to have_selector('.gl-text-orange-500')
    end
  end

  describe 'the groups dropdown' do
    context 'with multiple groups to choose from' do
      let(:project) { create(:project) }

      it 'includes multiple groups' do
        project.add_maintainer(maintainer)
        sign_in(maintainer)

        group1 = create(:group)
        group1.add_owner(maintainer)
        group2 = create(:group)
        group2.add_owner(maintainer)

        visit project_project_members_path(project)

        click_on 'Invite a group'
        click_on 'Select a group'
        wait_for_requests

        expect(page).to have_button(group1.name)
        expect(page).to have_button(group2.name)
      end
    end

    context 'for a project in a nested group' do
      let(:group) { create(:group) }
      let!(:nested_group) { create(:group, parent: group) }
      let!(:group_to_share_with) { create(:group) }
      let!(:project) { create(:project, namespace: nested_group) }

      before do
        project.add_maintainer(maintainer)
        sign_in(maintainer)
        group.add_maintainer(maintainer)
        group_to_share_with.add_maintainer(maintainer)
      end

      # This behavior should be changed to exclude the ancestor and project
      # group from the options once issue is fixed for the modal:
      # https://gitlab.com/gitlab-org/gitlab/-/issues/329835
      it 'the groups dropdown does show ancestors and the project group' do
        visit project_project_members_path(project)

        click_on 'Invite a group'
        click_on 'Select a group'
        wait_for_requests

        expect(page).to have_button(group_to_share_with.name)
        expect(page).to have_button(group.name)
        expect(page).to have_button(nested_group.name)
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Members > Manage members', :js, feature_category: :groups_and_projects do
  include ListboxHelpers
  include Features::MembersHelpers
  include Features::InviteMembersModalHelpers
  include Spec::Support::Helpers::ModalHelpers

  let_it_be(:user1) { create(:user, name: 'John Doe') }
  let_it_be(:user2) { create(:user, name: 'Mary Jane') }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :internal, namespace: group) }

  let(:project_owner) { create(:user, name: "ProjectOwner", username: "project_owner") }
  let(:project_maintainer) { create(:user, name: "ProjectMaintainer", username: "project_maintainer") }
  let(:group_owner) { user1 }
  let(:project_developer) { user2 }

  before do
    project.add_maintainer(project_maintainer)
    project.add_owner(project_owner)
    group.add_owner(group_owner)

    stub_feature_flags(show_role_details_in_drawer: false)
    sign_in(group_owner)
  end

  it 'show members from project and group', :aggregate_failures do
    project.add_developer(project_developer)

    visit_members_page

    expect(first_row).to have_content(group_owner.name)
    expect(second_row).to have_content(project_developer.name)
  end

  it 'show user once if member of both group and project', :aggregate_failures do
    group.add_reporter(project_maintainer)

    visit_members_page

    expect(first_row).to have_content(group_owner.name)
    expect(second_row).to have_content(project_maintainer.name)
    expect(third_row).to have_content(project_owner.name)
    expect(all_rows[3]).to be_blank
  end

  context 'update user access level' do
    before do
      sign_in(current_user)
    end

    context 'as maintainer' do
      let(:current_user) { project_maintainer }

      it 'can update a non-Owner member' do
        project.add_developer(project_developer)

        visit_members_page

        page.within find_member_row(project_developer) do
          click_button('Developer')

          expect_no_listbox_item('Owner')
          select_listbox_item('Reporter')

          expect(page).to have_button('Reporter')
        end
      end

      it 'cannot update an Owner member' do
        visit_members_page

        page.within find_member_row(project_owner) do
          expect(page).not_to have_button('Owner')
        end
      end
    end

    context 'as owner' do
      let(:current_user) { group_owner }

      it 'can update a project Owner member' do
        visit_members_page

        page.within find_member_row(project_owner) do
          select_from_listbox('Reporter', from: 'Owner')

          expect(page).to have_button('Reporter')
        end
      end
    end
  end

  context 'uses ProjectMember valid_access_level_roles for the invite members modal options', :aggregate_failures,
    quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/436958' do
    before do
      sign_in(current_user)

      visit_members_page

      click_on 'Invite members'

      wait_for_requests
    end

    context 'when owner' do
      let(:current_user) { project_owner }

      it 'shows Owner in the dropdown' do
        within_modal do
          toggle_listbox
          expect_listbox_items(%w[Guest Planner Reporter Developer Maintainer Owner])
        end
      end
    end

    context 'when maintainer' do
      let(:current_user) { project_maintainer }

      it 'does not show the Owner option' do
        within_modal do
          toggle_listbox
          expect_listbox_items(%w[Guest Planner Reporter Developer Maintainer])
        end
      end
    end
  end

  describe 'remove user from project' do
    before do
      project.add_developer(project_developer)

      sign_in(current_user)

      visit_members_page
    end

    context 'when maintainer' do
      let(:current_user) { project_maintainer }

      it 'can only remove non-Owner members' do
        page.within find_member_row(project_owner) do
          expect(page).not_to have_selector user_action_dropdown
        end

        show_actions_for_username(project_developer)
        click_button _('Remove member')

        within_modal do
          expect(page).to have_unchecked_field 'Also unassign this user from related issues and merge requests'
          click_button _('Remove member')
        end

        wait_for_requests

        expect(members_table).not_to have_content(project_developer.name)
        expect(members_table).to have_content(project_owner.name)
      end
    end

    context 'when owner' do
      let(:current_user) { group_owner }

      it 'can remove any direct member' do
        show_actions_for_username(project_owner)
        click_button _('Remove member')

        within_modal do
          expect(page).to have_unchecked_field 'Also unassign this user from related issues and merge requests'
          click_button _('Remove member')
        end

        wait_for_requests

        expect(members_table).not_to have_content(project_owner.name)
      end
    end
  end

  it_behaves_like 'inviting members', 'project_members_page' do
    let_it_be(:entity) { project }
    let_it_be(:members_page_path) { project_project_members_path(entity) }
    let_it_be(:subentity) { project }
    let_it_be(:subentity_members_page_path) { project_project_members_path(entity) }

    before do
      allow(Gitlab::QueryLimiting::Transaction).to receive(:threshold).and_return(112)
    end
  end

  describe 'member search results' do
    it 'does not show project_bots', :aggregate_failures do
      internal_project_bot = create(:user, :project_bot, name: '_internal_project_bot_')
      project.add_maintainer(internal_project_bot)

      external_group = create(:group)
      external_project_bot = create(:user, :project_bot, name: '_external_project_bot_')
      external_project = create(:project, group: external_group)
      external_project.add_maintainer(external_project_bot)
      external_project.add_maintainer(group_owner)

      visit_members_page

      click_on 'Invite members'

      page.within invite_modal_selector do
        field = find(member_dropdown_selector)
        field.native.send_keys :tab
        field.click

        wait_for_requests

        expect(page).to have_content(group_owner.name)
        expect(page).to have_content(project_developer.name)
        expect(page).not_to have_content(internal_project_bot.name)
        expect(page).not_to have_content(external_project_bot.name)
      end
    end
  end

  context 'as a signed out visitor viewing a public project' do
    let_it_be(:project) { create(:project, :public) }

    before do
      sign_out(group_owner)
    end

    it 'does not show the Invite members button when not signed in' do
      visit_members_page

      expect(page).not_to have_button('Invite members')
    end
  end

  context 'project bots' do
    let(:project_bot) { create(:user, :project_bot, name: 'project_bot') }

    before do
      project.add_maintainer(project_bot)
    end

    it 'does not show form used to change roles and "Expiration date" or the remove user button', :aggregate_failures do
      visit_members_page

      page.within find_username_row(project_bot) do
        expect(page).not_to have_button('Maintainer')
        expect(page).to have_field('Expiration date', disabled: true)
        expect(page).not_to have_button('Remove member')
      end
    end
  end

  describe 'when user has 2FA enabled' do
    let_it_be(:admin) { create(:admin) }
    let_it_be(:user_with_2fa) { create(:user, :two_factor_via_otp) }

    before do
      project.add_guest(user_with_2fa)
    end

    it 'shows 2FA badge to user with "Maintainer" access level' do
      sign_in(project_maintainer)

      visit_members_page

      expect(find_member_row(user_with_2fa)).to have_content('2FA')
    end

    it 'shows 2FA badge to admins' do
      sign_in(admin)
      enable_admin_mode!(admin)

      visit_members_page

      expect(find_member_row(user_with_2fa)).to have_content('2FA')
    end

    it 'does not show 2FA badge to users with access level below "Maintainer"' do
      group.add_developer(group_owner)

      visit_members_page

      expect(find_member_row(user_with_2fa)).not_to have_content('2FA')
    end

    it 'shows 2FA badge to themselves' do
      sign_in(user_with_2fa)

      visit_members_page

      expect(find_member_row(user_with_2fa)).to have_content('2FA')
    end
  end

  context 'planner role banner' do
    before do
      sign_in(user1)

      visit_members_page
    end

    it 'shows the planner role annoucement and persists dismissal' do
      expect(page).to have_content('New Planner role')

      within_testid('planner-role-banner') do
        find_by_testid('close-icon').click
      end

      expect(page).not_to have_content('New Planner role')

      page.refresh

      expect(page).not_to have_content('New Planner role')
    end
  end

  private

  def visit_members_page
    visit project_project_members_path(project)
  end
end

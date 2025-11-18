# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Members > Manage members', :js, feature_category: :groups_and_projects do
  include ListboxHelpers
  include Features::MembersHelpers
  include Features::InviteMembersModalHelpers
  include Spec::Support::Helpers::ModalHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :internal, namespace: group) }

  let_it_be(:user1) { create(:user, name: 'John Doe', owner_of: group) }
  let_it_be(:user2) { create(:user, name: 'Mary Jane') }

  let_it_be(:project_owner) { create(:user, owner_of: project) }
  let_it_be(:project_maintainer) { create(:user, maintainer_of: project) }
  let_it_be(:project_developer) { create(:user, developer_of: project) }
  let_it_be(:group_owner) { user1 }

  let(:current_user) { group_owner }

  before do
    stub_feature_flags(show_role_details_in_drawer: false)
    sign_in(current_user)
  end

  it 'show members from project and group', :aggregate_failures,
    quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/560627' do
    visit_members_page

    expect(first_row).to have_content(group_owner.name)
    expect(second_row).to have_content(project_owner.name)
    expect(third_row).to have_content(project_maintainer.name)
    expect(all_rows[3]).to have_content(project_developer.name)
  end

  it 'show user once if member of both group and project', :aggregate_failures,
    quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/560628' do
    group.add_reporter(project_maintainer)

    visit_members_page

    expect(first_row).to have_content(group_owner.name)
    expect(second_row).to have_content(project_owner.name)
    expect(third_row).to have_content(project_maintainer.name)
    expect(all_rows[3]).to have_content(project_developer.name)
    expect(all_rows[4]).to be_blank
  end

  context 'update user access level' do
    context 'when current user is a maintainer' do
      let(:current_user) { project_maintainer }

      it 'can update a non-owner member' do
        visit_members_page

        page.within find_member_row(project_developer) do
          click_button('Developer')

          expect_no_listbox_item('Owner')
          select_listbox_item('Reporter')

          expect(page).to have_button('Reporter')
        end
      end

      it 'cannot update an owner member' do
        visit_members_page

        page.within find_member_row(project_owner) do
          expect(page).not_to have_button('Owner')
        end
      end
    end

    context 'when current user is an owner' do
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

  context 'when inviting a member' do
    context 'when current user is an owner' do
      let(:current_user) { project_owner }

      it 'shows roles in the dropdown including `owner`' do
        visit_members_page

        click_on 'Invite members'

        page.within invite_modal_selector do
          page.within role_dropdown_selector do
            wait_for_requests
            toggle_listbox
            expect_listbox_items(%w[Guest Planner Reporter Developer Maintainer Owner])
          end
        end
      end
    end

    context 'when current user is a maintainer' do
      let(:current_user) { project_maintainer }

      it 'shows roles in the dropdown without `owner`' do
        visit_members_page

        click_on 'Invite members'

        page.within invite_modal_selector do
          page.within role_dropdown_selector do
            wait_for_requests
            toggle_listbox
            expect_listbox_items(%w[Guest Reporter Developer Maintainer])
          end
        end
      end
    end
  end

  describe 'remove user from project' do
    context 'when current user is a maintainer' do
      let(:current_user) { project_maintainer }

      it 'can only remove non-Owner members' do
        visit_members_page

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

    context 'when current user is an owner' do
      let(:current_user) { group_owner }

      it 'can remove any direct member' do
        visit_members_page

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
    let_it_be(:project_bot) { create(:user, :project_bot, name: 'project_bot') }

    before_all do
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
    let_it_be(:user_with_2fa) { create(:user, :two_factor_via_otp, guest_of: project) }

    context 'when current user is a maintainer' do
      let(:current_user) { project_maintainer }

      it 'shows 2FA badge' do
        visit_members_page

        expect(find_member_row(user_with_2fa)).to have_content('2FA')
      end
    end

    context 'when current user is an admin' do
      let(:current_user) { create(:admin) }

      it 'shows 2FA badge to admins', :enable_admin_mode do
        visit_members_page

        expect(find_member_row(user_with_2fa)).to have_content('2FA')
      end
    end

    context 'when current user is a developer' do
      let(:current_user) { project_developer }

      it 'does not show 2FA badge' do
        visit_members_page

        expect(find_member_row(user_with_2fa)).not_to have_content('2FA')
      end
    end

    context 'when current user is the user itself' do
      let(:current_user) { user_with_2fa }

      it 'shows 2FA badge to themselves' do
        visit_members_page

        expect(find_member_row(user_with_2fa)).to have_content('2FA')
      end
    end
  end

  private

  def visit_members_page
    visit project_project_members_path(project)
  end
end

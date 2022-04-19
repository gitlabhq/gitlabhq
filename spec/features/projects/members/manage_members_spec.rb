# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Members > Manage members', :js do
  include Spec::Support::Helpers::Features::MembersHelpers
  include Spec::Support::Helpers::Features::InviteMembersModalHelper
  include Spec::Support::Helpers::ModalHelpers

  let_it_be(:user1) { create(:user, name: 'John Doe') }
  let_it_be(:user2) { create(:user, name: 'Mary Jane') }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :internal, namespace: group) }

  before do
    sign_in(user1)
    group.add_owner(user1)
  end

  it 'show members from project and group', :aggregate_failures do
    project.add_developer(user2)

    visit_members_page

    expect(first_row).to have_content(user1.name)
    expect(second_row).to have_content(user2.name)
  end

  it 'show user once if member of both group and project', :aggregate_failures do
    project.add_developer(user1)

    visit_members_page

    expect(first_row).to have_content(user1.name)
    expect(second_row).to be_blank
  end

  it 'update user access level' do
    project.add_developer(user2)

    visit_members_page

    page.within find_member_row(user2) do
      click_button('Developer')
      click_button('Reporter')

      expect(page).to have_button('Reporter')
    end
  end

  it 'uses ProjectMember access_level_roles for the invite members modal access option', :aggregate_failures do
    visit_members_page

    click_on 'Invite members'

    click_on 'Guest'
    wait_for_requests

    page.within '.dropdown-menu' do
      expect(page).to have_button('Guest')
      expect(page).to have_button('Reporter')
      expect(page).to have_button('Developer')
      expect(page).to have_button('Maintainer')
      expect(page).not_to have_button('Owner')
    end
  end

  it 'remove user from project' do
    other_user = create(:user)
    project.add_developer(other_user)

    visit_members_page

    # Open modal
    page.within find_member_row(other_user) do
      click_button 'Remove member'
    end

    within_modal do
      expect(page).to have_unchecked_field 'Also unassign this user from related issues and merge requests'
      click_button('Remove member')
    end

    wait_for_requests

    expect(members_table).not_to have_content(other_user.name)
  end

  it_behaves_like 'inviting members', 'project-members-page' do
    let_it_be(:entity) { project }
    let_it_be(:members_page_path) { project_project_members_path(entity) }
    let_it_be(:subentity) { project }
    let_it_be(:subentity_members_page_path) { project_project_members_path(entity) }
  end

  describe 'member search results' do
    it 'does not show project_bots', :aggregate_failures do
      internal_project_bot = create(:user, :project_bot, name: '_internal_project_bot_')
      project.add_maintainer(internal_project_bot)

      external_group = create(:group)
      external_project_bot = create(:user, :project_bot, name: '_external_project_bot_')
      external_project = create(:project, group: external_group)
      external_project.add_maintainer(external_project_bot)
      external_project.add_maintainer(user1)

      visit_members_page

      click_on 'Invite members'

      page.within invite_modal_selector do
        field = find(member_dropdown_selector)
        field.native.send_keys :tab
        field.click

        wait_for_requests

        expect(page).to have_content(user1.name)
        expect(page).to have_content(user2.name)
        expect(page).not_to have_content(internal_project_bot.name)
        expect(page).not_to have_content(external_project_bot.name)
      end
    end
  end

  context 'as a signed out visitor viewing a public project' do
    let_it_be(:project) { create(:project, :public) }

    before do
      sign_out(user1)
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
      project.add_maintainer(user1)

      visit_members_page

      expect(find_member_row(user_with_2fa)).to have_content('2FA')
    end

    it 'shows 2FA badge to admins' do
      sign_in(admin)
      gitlab_enable_admin_mode_sign_in(admin)

      visit_members_page

      expect(find_member_row(user_with_2fa)).to have_content('2FA')
    end

    it 'does not show 2FA badge to users with access level below "Maintainer"' do
      group.add_developer(user1)

      visit_members_page

      expect(find_member_row(user_with_2fa)).not_to have_content('2FA')
    end

    it 'shows 2FA badge to themselves' do
      sign_in(user_with_2fa)

      visit_members_page

      expect(find_member_row(user_with_2fa)).to have_content('2FA')
    end
  end

  private

  def visit_members_page
    visit project_project_members_path(project)
  end
end

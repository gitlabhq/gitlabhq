# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Admin Groups', :with_current_organization, feature_category: :groups_and_projects do
  include Features::MembersHelpers
  include Features::InviteMembersModalHelpers
  include Spec::Support::Helpers::ModalHelpers

  let(:internal) { Gitlab::VisibilityLevel::INTERNAL }

  let_it_be(:user) { create :user }
  let_it_be(:group) { create :group }
  let_it_be_with_reload(:current_user) { create(:admin) }

  before do
    sign_in(current_user)
    enable_admin_mode!(current_user)
    stub_application_setting(default_group_visibility: internal)
  end

  describe 'list' do
    it 'renders groups' do
      visit admin_groups_path

      expect(page).to have_content(group.name)
    end
  end

  describe 'create a group', :js do
    describe 'with expected fields' do
      it 'renders from as expected', :aggregate_failures do
        visit new_admin_group_path

        expect(page).to have_field('name')
        expect(page).to have_field('group_path')
        expect(page).to have_field('group_visibility_level_0')
        expect(page).to have_field('description')
        expect(page).to have_field('group_admin_note_attributes_note')
      end
    end

    it 'creates new group' do
      visit admin_groups_path

      page.within '#content-body' do
        click_link "New group"
      end
      path_component = 'gitlab'
      group_name = 'GitLab group name'
      group_description = 'Description of group for GitLab'
      group_admin_note = 'A note about this group by an admin'

      fill_in 'group_path', with: path_component
      fill_in 'group_name', with: group_name
      fill_in 'group_description', with: group_description
      fill_in 'group_admin_note_attributes_note', with: group_admin_note
      click_button "Create group"

      expect(page).to have_current_path admin_group_path(Group.find_by(path: path_component)), ignore_query: true
      content = page.find('#content-body')
      expect(page).to have_content group_name
      li_texts = content.all('li').collect(&:text).join("\n")
      expect(li_texts).to match group_name
      expect(li_texts).to match path_component
      expect(li_texts).to match group_description
      p_texts = content.all('p').collect(&:text).join('/n')
      expect(p_texts).to match group_admin_note
    end

    it 'shows the visibility level radio populated with the default value' do
      visit new_admin_group_path

      expect_selected_visibility(internal)
    end

    it 'when entered in group name, it auto filled the group path' do
      visit admin_groups_path
      click_link "New group"
      group_name = 'gitlab'
      fill_in 'group_name', with: group_name
      path_field = find('input#group_path')
      expect(path_field.value).to eq group_name
    end

    it 'auto populates the group path with the group name' do
      visit admin_groups_path
      click_link "New group"
      group_name = 'my gitlab project'
      fill_in 'group_name', with: group_name
      path_field = find('input#group_path')
      expect(path_field.value).to eq 'my-gitlab-project'
    end

    it 'when entering in group path, group name does not change anymore' do
      visit admin_groups_path
      click_link "New group"
      group_path = 'my-gitlab-project'
      group_name = 'My modified gitlab project'
      fill_in 'group_path', with: group_path
      fill_in 'group_name', with: group_name
      path_field = find('input#group_path')
      expect(path_field.value).to eq 'my-gitlab-project'
    end
  end

  describe 'show a group' do
    it 'shows the group' do
      group = create(:group, :private)

      visit admin_group_path(group)

      expect(page).to have_content group.name
      expect(page).to have_content("ID: #{group.id}")
    end

    it 'shows an info text' do
      group = create(:group, :private)

      visit admin_group_path(group)

      expect(page).to have_content("The number of direct members in the current group. Members in subgroups are " \
        "not included. What is a direct member?")
      expect(page).to have_content("Calculations are made based on projects in the current group. " \
        "Projects in subgroups are not included.")
    end

    context 'with a subgroup' do
      it 'does not show an info text' do
        group = create(:group)
        subgroup = create(:group, parent: group)

        visit admin_group_path(subgroup)

        expect(page).not_to have_content("The number of direct members in the current group. Members in subgroups " \
          "are not included. What is a direct member?")
        expect(page).not_to have_content("Calculations are made based on projects in the current group. " \
          "Projects in subgroups are not included.")
      end
    end

    it 'has a link to the group' do
      group = create(:group, :private)

      visit admin_group_path(group)

      expect(page).to have_link(group.name, href: group_path(group))
    end

    it 'has a note if one is available' do
      group = create(:group, :private)
      note_text = 'A group administrator note'
      group.update!(admin_note_attributes: { note: note_text })

      visit admin_group_path(group)

      expect(page).to have_text(note_text)
    end

    context 'when group has open access requests' do
      let!(:access_request) { create(:group_member, :access_request, group: group) }

      it 'shows access requests with link to manage access' do
        visit admin_group_path(group)

        within_testid('access-requests') do
          expect(page).to have_content access_request.user.name
          expect(page).to have_link 'Manage access', href: group_group_members_path(group, tab: 'access_requests')
        end
      end
    end
  end

  describe 'group edit' do
    it 'shows all breadcrumbs', :js do
      visit admin_group_edit_path(group)

      expect(page_breadcrumbs).to eq([
        { text: 'Admin area', href: admin_root_path },
        { text: 'Groups', href: admin_groups_path },
        { text: group.name, href: admin_group_path(group) },
        { text: 'Edit', href: admin_group_edit_path(group) }
      ])
    end

    it 'shows the visibility level radio populated with the group visibility_level value' do
      group = create(:group, :private)

      visit admin_group_edit_path(group)

      expect_selected_visibility(group.visibility_level)
    end

    it 'shows the subgroup creation level dropdown populated with the group subgroup_creation_level value' do
      group = create(:group, :private, :owner_subgroup_creation_only)

      visit admin_group_edit_path(group)

      expect(page).to have_content('Roles allowed to create subgroups')
    end

    it 'edit group path does not change group name', :js do
      group = create(:group, :private)

      visit admin_group_edit_path(group)
      name_field = find('input#group_name')
      original_name = name_field.value
      fill_in 'group_path', with: 'this-new-path'

      expect(name_field.value).to eq original_name
    end

    it 'adding an admin note to group without one' do
      group = create(:group, :private)
      expect(group.admin_note).to be_nil

      visit admin_group_edit_path(group)
      admin_note_text = 'A note by an administrator'

      fill_in 'group_admin_note_attributes_note', with: admin_note_text
      click_button 'Save changes'

      expect(page).to have_content(admin_note_text)
    end

    it 'editing an existing group admin note' do
      admin_note_text = 'A note by an administrator'
      new_admin_note_text = 'A new note by an administrator'
      group = create(:group, :private)
      group.create_admin_note(note: admin_note_text)

      visit admin_group_edit_path(group)

      admin_note_field = find('#group_admin_note_attributes_note')
      expect(admin_note_field.value).to eq(admin_note_text)

      fill_in 'group_admin_note_attributes_note', with: new_admin_note_text
      click_button 'Save changes'

      expect(page).to have_content(new_admin_note_text)
    end

    it 'hides removed note' do
      group = create(:group, :private)
      group.create_admin_note(note: 'A note by an administrator')

      visit admin_group_edit_path(group)
      fill_in 'group_admin_note_attributes_note', with: ''
      click_button 'Save changes'

      expect(page).not_to have_content(s_('Admin|Admin notes'))
    end
  end

  describe 'add user into a group', :js do
    context 'when membership is set to expire' do
      it 'renders relative time', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/460029' do
        expire_time = Time.current + 2.days
        current_user.update!(time_display_relative: true)
        group.add_member(user, Gitlab::Access::REPORTER, expires_at: expire_time)

        visit admin_group_path(group)

        expect(page).to have_content(/Expires in \d day/)
      end

      it 'renders absolute time' do
        expire_time = Time.current.tomorrow.middle_of_day
        current_user.update!(time_display_relative: false)
        group.add_member(user, Gitlab::Access::REPORTER, expires_at: expire_time)

        visit admin_group_path(group)

        expect(page).to have_content("Expires on #{expire_time.strftime('%b %-d')}")
      end
    end
  end

  describe 'add admin himself to a group' do
    before do
      group.add_member(:user, Gitlab::Access::OWNER)
    end

    it 'adds admin a to a group as developer', :js do
      visit group_group_members_path(group)

      invite_member(current_user.name, role: 'Developer')

      page.within members_table do
        expect(page).to have_content(current_user.name)
        expect(page).to have_content('Developer')
      end
    end
  end

  describe 'admin removes themself from a group', :js do
    it 'removes admin from the group' do
      group.add_member(current_user, Gitlab::Access::DEVELOPER)

      visit group_group_members_path(group)

      page.within members_table do
        expect(page).to have_content(current_user.name)
        expect(page).to have_content('Developer')
      end

      show_actions_for_username(current_user)
      click_button _('Leave group')

      within_modal do
        click_button _('Leave')
      end

      wait_for_all_requests

      visit group_group_members_path(group)

      expect(page).to have_content('No results found')
    end
  end

  describe 'shared projects' do
    it 'renders shared project' do
      empty_project = create(:project)
      empty_project.project_group_links.create!(
        group_access: Gitlab::Access::MAINTAINER,
        group: group
      )

      visit admin_group_path(group)

      expect(page).to have_content(empty_project.full_name)
      expect(page).to have_content('Projects shared with')
    end
  end

  def expect_selected_visibility(level)
    selector = "#group_visibility_level_#{level}[checked=checked]"

    expect(page).to have_selector(selector, count: 1)
  end
end

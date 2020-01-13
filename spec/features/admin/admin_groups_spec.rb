# frozen_string_literal: true

require 'spec_helper'

describe 'Admin Groups' do
  include Select2Helper

  let(:internal) { Gitlab::VisibilityLevel::INTERNAL }
  let(:user) { create :user }
  let!(:group) { create :group }
  let!(:current_user) { create(:admin) }

  before do
    sign_in(current_user)
    stub_application_setting(default_group_visibility: internal)
  end

  describe 'list' do
    it 'renders groups' do
      visit admin_groups_path

      expect(page).to have_content(group.name)
    end
  end

  describe 'create a group' do
    it 'creates new group' do
      visit admin_groups_path

      page.within '#content-body' do
        click_link "New group"
      end
      path_component = 'gitlab'
      group_name = 'GitLab group name'
      group_description = 'Description of group for GitLab'

      fill_in 'group_path', with: path_component
      fill_in 'group_name', with: group_name
      fill_in 'group_description', with: group_description
      click_button "Create group"

      expect(current_path).to eq admin_group_path(Group.find_by(path: path_component))
      content = page.find('div#content-body')
      h3_texts = content.all('h3').collect(&:text).join("\n")
      expect(h3_texts).to match group_name
      li_texts = content.all('li').collect(&:text).join("\n")
      expect(li_texts).to match group_name
      expect(li_texts).to match path_component
      expect(li_texts).to match group_description
    end

    it 'shows the visibility level radio populated with the default value' do
      visit new_admin_group_path

      expect_selected_visibility(internal)
    end

    it 'when entered in group name, it auto filled the group path', :js do
      visit admin_groups_path
      click_link "New group"
      group_name = 'gitlab'
      fill_in 'group_name', with: group_name
      path_field = find('input#group_path')
      expect(path_field.value).to eq group_name
    end

    it 'auto populates the group path with the group name', :js do
      visit admin_groups_path
      click_link "New group"
      group_name = 'my gitlab project'
      fill_in 'group_name', with: group_name
      path_field = find('input#group_path')
      expect(path_field.value).to eq 'my-gitlab-project'
    end

    it 'when entering in group path, group name does not change anymore', :js do
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

      expect(page).to have_content("Group: #{group.name}")
      expect(page).to have_content("ID: #{group.id}")
    end

    it 'has a link to the group' do
      group = create(:group, :private)

      visit admin_group_path(group)

      expect(page).to have_link(group.name, href: group_path(group))
    end
  end

  describe 'group edit' do
    it 'shows the visibility level radio populated with the group visibility_level value' do
      group = create(:group, :private)

      visit admin_group_edit_path(group)

      expect_selected_visibility(group.visibility_level)
    end

    it 'shows the subgroup creation level dropdown populated with the group subgroup_creation_level value' do
      group = create(:group, :private, :owner_subgroup_creation_only)

      visit admin_group_edit_path(group)

      expect(page).to have_content('Allowed to create subgroups')
    end

    it 'edit group path does not change group name', :js do
      group = create(:group, :private)

      visit admin_group_edit_path(group)
      name_field = find('input#group_name')
      original_name = name_field.value
      fill_in 'group_path', with: 'this-new-path'

      expect(name_field.value).to eq original_name
    end
  end

  describe 'add user into a group', :js do
    shared_context 'adds user into a group' do
      it do
        visit admin_group_path(group)

        select2(user_selector, from: '#user_ids', multiple: true)
        page.within '#new_project_member' do
          select2(Gitlab::Access::REPORTER, from: '#access_level')
        end
        click_button "Add users to group"
        page.within ".group-users-list" do
          expect(page).to have_content(user.name)
          expect(page).to have_content('Reporter')
        end
      end
    end

    it_behaves_like 'adds user into a group' do
      let(:user_selector) { user.id }
    end

    it_behaves_like 'adds user into a group' do
      let(:user_selector) { user.email }
    end
  end

  describe 'add admin himself to a group' do
    before do
      group.add_user(:user, Gitlab::Access::OWNER)
    end

    it 'adds admin a to a group as developer', :js do
      visit group_group_members_path(group)

      page.within '.invite-users-form' do
        select2(current_user.id, from: '#user_ids', multiple: true)
        select 'Developer', from: 'access_level'
      end

      click_button 'Invite'

      page.within '[data-qa-selector="members_list"]' do
        expect(page).to have_content(current_user.name)
        expect(page).to have_content('Developer')
      end
    end
  end

  describe 'admin remove himself from a group', :js do
    it 'removes admin from the group' do
      group.add_user(current_user, Gitlab::Access::DEVELOPER)

      visit group_group_members_path(group)

      page.within '[data-qa-selector="members_list"]' do
        expect(page).to have_content(current_user.name)
        expect(page).to have_content('Developer')
      end

      accept_confirm { find(:css, 'li', text: current_user.name).find(:css, 'a.btn-remove').click }

      visit group_group_members_path(group)

      page.within '[data-qa-selector="members_list"]' do
        expect(page).not_to have_content(current_user.name)
        expect(page).not_to have_content('Developer')
      end
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

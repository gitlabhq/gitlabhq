# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Edit group settings', feature_category: :subgroups do
  let(:user)  { create(:user) }
  let(:group) { create(:group, path: 'foo') }

  before do
    group.add_owner(user)
    sign_in(user)
  end

  describe 'when the group path is changed' do
    let(:new_group_path) { 'bar' }
    let(:old_group_full_path) { "/#{group.path}" }
    let(:new_group_full_path) { "/#{new_group_path}" }

    it 'the group is accessible via the new path' do
      update_path(new_group_path)
      visit new_group_full_path

      expect(page).to have_current_path(new_group_full_path, ignore_query: true)
      expect(find('h1.home-panel-title')).to have_content(group.name)
    end

    it 'the old group path redirects to the new path' do
      update_path(new_group_path)
      visit old_group_full_path

      expect(page).to have_current_path(new_group_full_path, ignore_query: true)
      expect(find('h1.home-panel-title')).to have_content(group.name)
    end

    context 'with a subgroup' do
      let!(:subgroup) { create(:group, parent: group, path: 'subgroup') }
      let(:old_subgroup_full_path) { "/#{group.path}/#{subgroup.path}" }
      let(:new_subgroup_full_path) { "/#{new_group_path}/#{subgroup.path}" }

      it 'the subgroup is accessible via the new path' do
        update_path(new_group_path)
        visit new_subgroup_full_path

        expect(page).to have_current_path(new_subgroup_full_path, ignore_query: true)
        expect(find('h1.home-panel-title')).to have_content(subgroup.name)
      end

      it 'the old subgroup path redirects to the new path' do
        update_path(new_group_path)
        visit old_subgroup_full_path

        expect(page).to have_current_path(new_subgroup_full_path, ignore_query: true)
        expect(find('h1.home-panel-title')).to have_content(subgroup.name)
      end
    end

    context 'with a project' do
      let!(:project) { create(:project, group: group) }
      let(:old_project_full_path) { "/#{group.path}/#{project.path}" }
      let(:new_project_full_path) { "/#{new_group_path}/#{project.path}" }

      before(:context) do
        TestEnv.clean_test_path
      end

      after do
        TestEnv.clean_test_path
      end

      it 'the project is accessible via the new path' do
        update_path(new_group_path)
        visit new_project_full_path

        expect(page).to have_current_path(new_project_full_path, ignore_query: true)
        expect(find('.breadcrumbs')).to have_content(project.path)
      end

      it 'the old project path redirects to the new path' do
        update_path(new_group_path)
        visit old_project_full_path

        expect(page).to have_current_path(new_project_full_path, ignore_query: true)
        expect(find('.breadcrumbs')).to have_content(project.path)
      end
    end
  end

  describe 'project creation level menu' do
    it 'shows the selection menu' do
      visit edit_group_path(group)

      expect(page).to have_content('Roles allowed to create projects')
    end
  end

  describe 'subgroup creation level menu' do
    it 'shows the selection menu' do
      visit edit_group_path(group)

      expect(page).to have_content('Roles allowed to create subgroups')
    end
  end

  describe 'edit group avatar' do
    before do
      visit edit_group_path(group)

      attach_file(:group_avatar, Rails.root.join('spec', 'fixtures', 'banana_sample.gif'))

      expect { save_general_group }.to change { group.reload.avatar? }.to(true)
    end

    it 'uploads new group avatar' do
      expect(group.avatar).to be_instance_of AvatarUploader
      expect(group.avatar.url).to eq "/uploads/-/system/group/avatar/#{group.id}/banana_sample.gif"
      expect(page).to have_link('Remove avatar')
    end

    it 'removes group avatar' do
      expect { click_link 'Remove avatar' }.to change { group.reload.avatar? }.to(false)
      expect(page).not_to have_link('Remove avatar')
    end
  end

  describe 'edit group path' do
    it 'has a root URL label for top-level group' do
      visit edit_group_path(group)

      expect(find(:css, '.group-root-path').text).to eq(root_url)
    end

    it 'has a parent group URL label for a subgroup group' do
      subgroup = create(:group, parent: group)

      visit edit_group_path(subgroup)

      expect(find(:css, '.group-root-path').text).to eq(group_url(subgroup.parent) + '/')
    end
  end

  describe 'transfer group', :js do
    let(:namespace_select) { page.find('[data-testid="transfer-group-namespace-select"]') }
    let(:confirm_modal) { page.find('[data-testid="confirm-danger-modal"]') }

    shared_examples 'can transfer the group' do
      before do
        selected_group.add_owner(user)
      end

      it 'can successfully transfer the group' do
        visit edit_group_path(selected_group)

        page.within('[data-testid="transfer-locations-dropdown"]') do
          click_button _('Select parent group')
          fill_in _('Search'), with: target_group_name
          wait_for_requests
          click_button target_group_name
        end

        click_button s_('GroupSettings|Transfer group')

        page.within(confirm_modal) do
          expect(page).to have_text "You are going to transfer #{selected_group.name} to another namespace. Are you ABSOLUTELY sure?"

          fill_in 'confirm_name_input', with: selected_group.name
          click_button 'Confirm'
        end

        expect(page).to have_text "Group '#{selected_group.name}' was successfully transferred."
        expect(current_url).to include(selected_group.reload.full_path)
      end
    end

    context 'when transfering from a subgroup' do
      let(:selected_group) { create(:group, path: 'foo-subgroup', parent: group) }

      context 'when transfering to no parent group' do
        let(:target_group_name) { 'No parent group' }

        it_behaves_like 'can transfer the group'
      end

      context 'when transfering to a parent group' do
        let(:target_group) { create(:group, path: 'foo-parentgroup') }
        let(:target_group_name) { target_group.name }

        before do
          target_group.add_owner(user)
        end

        it_behaves_like 'can transfer the group'
      end
    end

    context 'when transfering from a root group to a parent group' do
      let(:selected_group) { create(:group, path: 'foo-rootgroup') }
      let(:target_group_name) { group.name }

      it_behaves_like 'can transfer the group'
    end
  end

  context 'disable email notifications' do
    it 'is visible' do
      visit edit_group_path(group)

      expect(page).to have_selector('#group_emails_disabled', visible: true)
    end

    it 'accepts the changed state' do
      visit edit_group_path(group)
      check 'group_emails_disabled'

      expect { save_permissions_group }.to change { updated_emails_disabled? }.to(true)
    end
  end

  describe 'prevent sharing outside group hierarchy setting' do
    it 'updates the setting' do
      visit edit_group_path(group)

      check 'group_prevent_sharing_groups_outside_hierarchy'

      expect { save_permissions_group }.to change {
        group.reload.prevent_sharing_groups_outside_hierarchy
      }.to(true)
    end

    it 'is not present for a subgroup' do
      subgroup = create(:group, parent: group)
      visit edit_group_path(subgroup)

      expect(page).to have_text "Permissions"
      expect(page).not_to have_selector('#group_prevent_sharing_groups_outside_hierarchy')
    end
  end

  def update_path(new_group_path)
    visit edit_group_path(group)

    page.within('.gs-advanced') do
      fill_in 'group_path', with: new_group_path
      click_button 'Change group URL'
    end
  end

  def save_general_group
    page.within('.gs-general') do
      click_button 'Save changes'
    end
  end

  def save_permissions_group
    page.within('.gs-permissions') do
      click_button 'Save changes'
    end
  end

  def updated_emails_disabled?
    group.reload.clear_memoization(:emails_disabled_memoized)
    group.emails_disabled?
  end
end

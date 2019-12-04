# frozen_string_literal: true

require 'spec_helper'

describe 'Edit group settings' do
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

      expect(current_path).to eq(new_group_full_path)
      expect(find('h1.home-panel-title')).to have_content(group.name)
    end

    it 'the old group path redirects to the new path' do
      update_path(new_group_path)
      visit old_group_full_path

      expect(current_path).to eq(new_group_full_path)
      expect(find('h1.home-panel-title')).to have_content(group.name)
    end

    context 'with a subgroup' do
      let!(:subgroup) { create(:group, parent: group, path: 'subgroup') }
      let(:old_subgroup_full_path) { "/#{group.path}/#{subgroup.path}" }
      let(:new_subgroup_full_path) { "/#{new_group_path}/#{subgroup.path}" }

      it 'the subgroup is accessible via the new path' do
        update_path(new_group_path)
        visit new_subgroup_full_path

        expect(current_path).to eq(new_subgroup_full_path)
        expect(find('h1.home-panel-title')).to have_content(subgroup.name)
      end

      it 'the old subgroup path redirects to the new path' do
        update_path(new_group_path)
        visit old_subgroup_full_path

        expect(current_path).to eq(new_subgroup_full_path)
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

        expect(current_path).to eq(new_project_full_path)
        expect(find('.breadcrumbs')).to have_content(project.path)
      end

      it 'the old project path redirects to the new path' do
        update_path(new_group_path)
        visit old_project_full_path

        expect(current_path).to eq(new_project_full_path)
        expect(find('.breadcrumbs')).to have_content(project.path)
      end
    end
  end

  describe 'project creation level menu' do
    it 'shows the selection menu' do
      visit edit_group_path(group)

      expect(page).to have_content('Allowed to create projects')
    end
  end

  describe 'subgroup creation level menu' do
    it 'shows the selection menu' do
      visit edit_group_path(group)

      expect(page).to have_content('Allowed to create subgroups')
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

  def update_path(new_group_path)
    visit edit_group_path(group)

    page.within('.gs-advanced') do
      fill_in 'group_path', with: new_group_path
      click_button 'Change group path'
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
    group.reload.clear_memoization(:emails_disabled)
    group.emails_disabled?
  end
end

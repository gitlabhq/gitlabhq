require 'spec_helper'

feature 'Project group links', :feature, :js do
  include Select2Helper

  let(:master) { create(:user) }
  let(:project) { create(:project) }
  let!(:group) { create(:group) }

  background do
    project.add_master(master)
    login_as(master)
  end

  context 'setting an expiration date for a group link' do
    before do
      visit namespace_project_settings_members_path(project.namespace, project)

      select2 group.id, from: '#link_group_id'
      fill_in 'expires_at_groups', with: (Time.current + 4.5.days).strftime('%Y-%m-%d')
      page.find('body').click
      click_on 'Share'
    end

    it 'shows the expiration time with a warning class' do
      page.within('.enabled-groups') do
        expect(page).to have_content('expires in 4 days')
        expect(page).to have_selector('.text-warning')
      end
    end
  end

  context 'nested group project' do
    let!(:nested_group) { create(:group, parent: group) }
    let!(:another_group) { create(:group) }
    let!(:project) { create(:project, namespace: nested_group) }

    background do
      group.add_master(master)
      another_group.add_master(master)
    end

    it 'does not show ancestors' do
      visit namespace_project_settings_members_path(project.namespace, project)

      click_link 'Search for a group'

      page.within '.select2-drop' do
        expect(page).to have_content(another_group.name)
        expect(page).not_to have_content(group.name)
      end
    end
  end

  describe 'the groups dropdown' do
    before do
      group_two = create(:group)
      group.add_owner(master)
      group_two.add_owner(master)

      visit namespace_project_settings_members_path(project.namespace, project)
      execute_script 'GroupsSelect.PER_PAGE = 1;'
      open_select2 '#link_group_id'
    end

    it 'should infinitely scroll' do
      expect(find('.select2-drop .select2-results')).to have_selector('.select2-result', count: 1)

      scroll_select2_to_bottom('.select2-drop .select2-results:visible')

      expect(find('.select2-drop .select2-results')).to have_selector('.select2-result', count: 2)
    end
  end
end

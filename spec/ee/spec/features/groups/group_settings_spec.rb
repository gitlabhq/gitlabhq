require 'spec_helper'

feature 'Edit group settings' do
  given(:user)  { create(:user) }
  given(:group) { create(:group, path: 'foo') }

  background do
    group.add_owner(user)
    sign_in(user)
  end

  context 'with webhook feature enabled' do
    it 'shows the menu item' do
      stub_licensed_features(group_webhooks: true)

      visit edit_group_path(group)

      within('.nav-sidebar') do
        expect(page).to have_link('Webhooks')
      end
    end
  end

  context 'with webhook feature enabled' do
    it 'shows the menu item' do
      stub_licensed_features(group_webhooks: false)

      visit edit_group_path(group)

      within('.nav-sidebar') do
        expect(page).not_to have_link('Webhooks')
      end
    end
  end

  context 'with project_creation_level feature enabled' do
    it 'shows the selection menu' do
      stub_licensed_features(project_creation_level: true)

      visit edit_group_path(group)

      expect(page).to have_content('Allowed to create projects')
    end
  end

  context 'with project_creation_level feature disabled' do
    it 'shows the selection menu' do
      stub_licensed_features(project_creation_level: false)

      visit edit_group_path(group)

      expect(page).not_to have_content('Allowed to create projects')
    end
  end
end

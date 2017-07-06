require 'spec_helper'

feature 'Edit group settings', feature: true do
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

      within('.sub-nav') do
        expect(page).to have_link('Webhooks')
      end
    end
  end

  context 'with webhook feature enabled' do
    it 'shows the menu item' do
      stub_licensed_features(group_webhooks: false)

      visit edit_group_path(group)

      within('.sub-nav') do
        expect(page).not_to have_link('Webhooks')
      end
    end
  end
end

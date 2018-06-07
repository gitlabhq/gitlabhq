require 'spec_helper'

feature 'Edit group settings' do
  given(:user)  { create(:user) }
  given(:developer)  { create(:user) }
  given(:group) { create(:group, path: 'foo') }

  background do
    group.add_owner(user)
    group.add_developer(developer)
    sign_in(user)
  end

  describe 'navbar' do
    context 'with LDAP enabled' do
      before do
        allow_any_instance_of(EE::Group).to receive(:ldap_synced?).and_return(true)
        allow(Gitlab::Auth::LDAP::Config).to receive(:enabled?).and_return(true)
      end

      scenario 'is able to navigate to LDAP group section' do
        visit edit_group_path(group)

        expect(find('.nav-sidebar')).to have_content('LDAP Synchronization')
      end

      context 'with owners not being able to manage LDAP' do
        scenario 'is not able to navigate to LDAP group section' do
          stub_application_setting(allow_group_owners_to_manage_ldap: false)

          visit edit_group_path(group)

          expect(find('.nav-sidebar')).not_to have_content('LDAP Synchronization')
        end
      end
    end
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

  describe 'Member Lock setting' do
    context 'without a license key' do
      before do
        License.delete_all
      end

      it 'is not visible' do
        visit edit_group_path(group)

        expect(page).not_to have_content('Member lock')
      end
    end

    context 'with a license key' do
      it 'is visible' do
        visit edit_group_path(group)

        expect(page).to have_content('Member lock')
      end

      context 'when current user is not the Owner' do
        before do
          sign_in(developer)
        end

        it 'is not visible' do
          visit edit_group_path(group)

          expect(page).not_to have_content('Member lock')
        end
      end
    end
  end
end

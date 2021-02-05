# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "Admin::Users" do
  let(:current_user) { create(:admin) }

  before do
    sign_in(current_user)
    gitlab_enable_admin_mode_sign_in(current_user)
  end

  describe 'Tabs', :js do
    let(:tabs_selector) { '.js-users-tabs' }
    let(:active_tab_selector) { '.nav-link.active' }

    it 'does not add the tab param when the Users tab is selected' do
      visit admin_users_path

      within tabs_selector do
        click_link 'Users'
      end

      expect(page).to have_current_path(admin_users_path)
    end

    it 'adds the ?tab=cohorts param when the Cohorts tab is selected' do
      visit admin_users_path

      within tabs_selector do
        click_link 'Cohorts'
      end

      expect(page).to have_current_path(admin_users_path(tab: 'cohorts'))
    end

    it 'shows the cohorts tab when the tab param is set' do
      visit admin_users_path(tab: 'cohorts')

      within tabs_selector do
        expect(page).to have_selector active_tab_selector, text: 'Cohorts'
      end
    end
  end

  describe 'Cohorts tab content' do
    context 'with usage ping enabled' do
      it 'shows users count per month' do
        stub_application_setting(usage_ping_enabled: true)

        create_list(:user, 2)

        visit admin_users_path(tab: 'cohorts')

        expect(page).to have_content("#{Time.now.strftime('%b %Y')} 3 0")
      end
    end

    context 'with usage ping disabled' do
      it 'shows empty state', :js do
        stub_application_setting(usage_ping_enabled: false)

        visit admin_users_path(tab: 'cohorts')

        expect(page).to have_selector(".js-empty-state")
        expect(page).to have_content("Activate user activity analysis")
      end
    end
  end
end

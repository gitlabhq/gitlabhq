# frozen_string_literal: true

require "spec_helper"

RSpec.describe "renders a `whats new` dropdown item", :js, feature_category: :onboarding do
  let_it_be(:user) { create(:user) }

  context 'when not logged in' do
    it 'and on SaaS it renders', :saas do
      visit user_path(user)

      within_testid('super-sidebar') { click_on 'Help' }

      expect(page).to have_button(text: "What's new")
    end

    it "doesn't render what's new" do
      visit user_path(user)

      within_testid('super-sidebar') { click_on 'Help' }

      expect(page).not_to have_button(text: "What's new")
    end
  end

  context 'when logged in' do
    before do
      sign_in(user)
    end

    it 'renders dropdown item when feature enabled' do
      Gitlab::CurrentSettings.update!(whats_new_variant: ApplicationSetting.whats_new_variants[:all_tiers])

      visit root_dashboard_path
      within_testid('super-sidebar') { click_on 'Help' }

      expect(page).to have_button(text: "What's new")
    end

    it 'does not render dropdown item when feature disabled' do
      Gitlab::CurrentSettings.update!(whats_new_variant: ApplicationSetting.whats_new_variants[:disabled])

      visit root_dashboard_path
      within_testid('super-sidebar') { click_on 'Help' }

      expect(page).not_to have_button(text: "What's new")
    end

    it 'shows notification count and removes it once viewed' do
      visit root_dashboard_path

      within_testid('super-sidebar') do
        find_by_testid('sidebar-help-button').click

        within_testid('disclosure-content') { expect(page).not_to have_button(text: "What's new") }

        find_by_testid('sidebar-help-button').click

        has_testid?('notification-count', visible: true)

        click_on "What's new"
      end

      find('.whats-new-drawer .gl-drawer-close-button').click

      expect(find('.gl-toast')).to have_content("What's new moved to Help.")

      within_testid('super-sidebar') do
        expect(page).not_to have_button(text: "What's new")
        has_testid?('notification-count', visible: false)

        find_by_testid('sidebar-help-button').click

        within_testid('disclosure-content') { expect(page).to have_button(text: "What's new") }
      end
    end
  end
end

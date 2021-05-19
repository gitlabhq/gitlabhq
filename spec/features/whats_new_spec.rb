# frozen_string_literal: true

require "spec_helper"

RSpec.describe "renders a `whats new` dropdown item" do
  let_it_be(:user) { create(:user) }

  context 'when not logged in' do
    it 'and on .com it renders' do
      allow(Gitlab).to receive(:com?).and_return(true)

      visit user_path(user)

      page.within '.header-help' do
        find('.header-help-dropdown-toggle').click

        expect(page).to have_button(text: "What's new")
      end
    end

    it "doesn't render what's new" do
      visit user_path(user)

      page.within '.header-help' do
        find('.header-help-dropdown-toggle').click

        expect(page).not_to have_button(text: "What's new")
      end
    end
  end

  context 'when logged in', :js do
    before do
      sign_in(user)
    end

    it 'renders dropdown item when feature enabled' do
      Gitlab::CurrentSettings.update!(whats_new_variant: ApplicationSetting.whats_new_variants[:all_tiers])

      visit root_dashboard_path
      find('.header-help-dropdown-toggle').click

      expect(page).to have_button(text: "What's new")
    end

    it 'does not render dropdown item when feature disabled' do
      Gitlab::CurrentSettings.update!(whats_new_variant: ApplicationSetting.whats_new_variants[:disabled])

      visit root_dashboard_path
      find('.header-help-dropdown-toggle').click

      expect(page).not_to have_button(text: "What's new")
    end

    it 'shows notification dot and count and removes it once viewed' do
      visit root_dashboard_path

      page.within '.header-help' do
        expect(page).to have_selector('.notification-dot', visible: true)

        find('.header-help-dropdown-toggle').click

        expect(page).to have_button(text: "What's new")
        expect(page).to have_selector('.js-whats-new-notification-count')

        find('button', text: "What's new").click
      end

      find('.whats-new-drawer .gl-drawer-close-button').click
      find('.header-help-dropdown-toggle').click

      page.within '.header-help' do
        expect(page).not_to have_selector('.notification-dot', visible: true)
        expect(page).to have_button(text: "What's new")
        expect(page).not_to have_selector('.js-whats-new-notification-count')
      end
    end
  end
end

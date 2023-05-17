# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'new navigation toggle', :js, feature_category: :navigation do
  let_it_be(:user) { create(:user) }

  before do
    user.update!(use_new_navigation: user_preference)
    stub_feature_flags(super_sidebar_nav: new_nav_ff)
    sign_in(user)
    visit explore_projects_path
  end

  context 'with feature flag off' do
    let(:new_nav_ff) { false }

    where(:user_preference) do
      [true, false]
    end

    with_them do
      it 'shows old topbar user dropdown with no way to toggle to new nav' do
        within '.js-header-content .js-nav-user-dropdown' do
          find('a[data-toggle="dropdown"]').click
          expect(page).not_to have_content('Navigation redesign')
        end
      end
    end
  end

  context 'with feature flag on' do
    let(:new_nav_ff) { true }

    context 'when user has new nav disabled' do
      let(:user_preference) { false }

      it 'allows to enable new nav', :aggregate_failures do
        within '.js-nav-user-dropdown' do
          find('a[data-toggle="dropdown"]').click
          expect(page).to have_content('Navigation redesign')

          toggle = page.find('.gl-toggle:not(.is-checked)')
          toggle.click # reloads the page
        end

        wait_for_requests

        expect(user.reload.use_new_navigation).to eq true
      end

      it 'shows the old navigation' do
        expect(page).to have_selector('.js-navbar')
        expect(page).not_to have_selector('[data-testid="super-sidebar"]')
      end
    end

    context 'when user has new nav enabled' do
      let(:user_preference) { true }

      it 'allows to disable new nav', :aggregate_failures do
        within '[data-testid="super-sidebar"] [data-testid="user-dropdown"]' do
          click_button "#{user.name} user’s menu"
          expect(page).to have_content('Navigation redesign')

          toggle = page.find('.gl-toggle.is-checked')
          toggle.click # reloads the page
        end

        wait_for_requests

        expect(user.reload.use_new_navigation).to eq false
      end

      it 'shows the new navigation' do
        expect(page).not_to have_selector('.js-navbar')
        expect(page).to have_selector('[data-testid="super-sidebar"]')
      end
    end
  end
end

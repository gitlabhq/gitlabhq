# frozen_string_literal: true

require "spec_helper"

RSpec.describe "renders a `whats new` dropdown item", :js, feature_category: :onboarding do
  let_it_be(:user) { create(:user) }

  context 'when not logged in' do
    it 'and on SaaS it renders', :saas do
      visit user_path(user)

      expect(page).to have_button(text: "What's new")
    end

    it "doesn't render what's new" do
      visit user_path(user)

      expect(page).not_to have_button(text: "What's new")

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

      expect(page).to have_button(text: "What's new")
    end

    it 'does not render dropdown item when feature disabled' do
      Gitlab::CurrentSettings.update!(whats_new_variant: ApplicationSetting.whats_new_variants[:disabled])

      visit root_dashboard_path

      expect(page).not_to have_button(text: "What's new")
    end

    describe 'with notification count in the sidebar' do
      before do
        redis_set_key = "whats_new:#{ReleaseHighlight.most_recent_version_digest}:user:#{user.id}:read_articles"

        Gitlab::Redis::SharedState.with do |redis|
          redis.sadd(redis_set_key, *(2..ReleaseHighlight.most_recent_item_count))
        end
      end

      it 'shows the count and removes it once all articles are read' do
        visit root_dashboard_path

        within_testid('super-sidebar') do
          find_by_testid('sidebar-help-button').click

          within_testid('disclosure-content') { expect(page).not_to have_button(text: "What's new") }

          find_by_testid('sidebar-help-button').click

          has_testid?('notification-count', visible: true)

          click_on "What's new"
        end

        within '.whats-new-drawer' do
          find_by_testid('unread-article-icon').click

          find_by_testid('whats-new-article-close').click

          wait_for_all_requests

          find('.gl-drawer-close-button').click
        end

        expect(find('.gl-toast')).to have_content("What's new moved to Help.")

        within_testid('super-sidebar') do
          expect(page).not_to have_button(text: "What's new")
          has_testid?('notification-count', visible: false)

          find_by_testid('sidebar-help-button').click

          within_testid('disclosure-content') { expect(page).to have_button(text: "What's new") }
        end
      end
    end

    it 'renders two feature cards in the drawer' do
      visit root_dashboard_path

      within_testid('super-sidebar') do
        click_on "What's new"
      end

      expect(page).to have_css("[data-testid='granular-controls-feature-card']")

      find_by_testid('card-carousel-next-button').click

      expect(page).to have_css("[data-testid='duo-core-feature-card']")
    end
  end

  context 'when items in the latest release does not populate the infinite scroll fully', :saas do
    it 'automatically fetches more items' do
      visit user_path(user)

      page.current_window.resize_to(1200, 2400)

      within_testid('super-sidebar') { click_on "What's new" }

      expect(page).to have_selector('[data-testid="whats-new-release-heading"]', minimum: 2)
    end
  end
end

# frozen_string_literal: true

require "spec_helper"

RSpec.describe "renders a `whats new` dropdown item", :js, feature_category: :onboarding do
  let_it_be(:user) { create(:user) }

  def open_help_dropdown
    within_testid('super-sidebar') { find_by_testid('sidebar-help-button').click }
  end

  context 'when not logged in' do
    it 'renders inside the help dropdown on SaaS', :saas do
      visit user_path(user)

      open_help_dropdown

      within_testid('disclosure-content') do
        expect(page).to have_button(text: "What's new")
      end
    end

    it "doesn't render what's new on self-managed" do
      visit user_path(user)

      open_help_dropdown

      within_testid('disclosure-content') do
        expect(page).not_to have_button(text: "What's new")
      end
    end
  end

  context 'when logged in' do
    before do
      sign_in(user)
    end

    it 'renders dropdown item when feature enabled' do
      Gitlab::CurrentSettings.update!(whats_new_variant: ApplicationSetting.whats_new_variants[:all_tiers])

      visit root_dashboard_path

      open_help_dropdown

      within_testid('disclosure-content') do
        expect(page).to have_button(text: "What's new")
      end
    end

    it 'does not render dropdown item when feature disabled' do
      Gitlab::CurrentSettings.update!(whats_new_variant: ApplicationSetting.whats_new_variants[:disabled])

      visit root_dashboard_path

      open_help_dropdown

      within_testid('disclosure-content') do
        expect(page).not_to have_button(text: "What's new")
      end
    end

    describe 'with unread articles' do
      before do
        redis_set_key = "whats_new:#{ReleaseHighlight.most_recent_version_digest}:user:#{user.id}:read_articles"

        Gitlab::Redis::SharedState.with do |redis|
          redis.sadd(redis_set_key, *(2..ReleaseHighlight.most_recent_item_count))
        end
      end

      it 'keeps the menu item full-time after all articles are read' do
        visit root_dashboard_path

        open_help_dropdown

        within_testid('disclosure-content') do
          expect(page).to have_button(text: "What's new")
          click_on "What's new"
        end

        within '.whats-new-drawer' do
          find_by_testid('unread-article-icon').click

          find_by_testid('whats-new-article-close').click

          wait_for_all_requests

          find('.gl-drawer-close-button').click
        end

        open_help_dropdown

        within_testid('disclosure-content') do
          expect(page).to have_button(text: "What's new")
        end
      end
    end
  end

  context 'when items in the latest release does not populate the infinite scroll fully', :saas do
    it 'automatically fetches more items' do
      visit user_path(user)

      page.current_window.resize_to(1200, 2400)

      open_help_dropdown

      within_testid('disclosure-content') { click_on "What's new" }

      expect(page).to have_selector('[data-testid="whats-new-release-heading"]', minimum: 2)
    end
  end
end

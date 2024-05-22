# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'new navigation for everyone callout', :js, feature_category: :navigation do
  let_it_be(:callout_title) { _('GitLab has redesigned the left sidebar to address customer feedback') }

  before do
    sign_in(user)
    visit root_path
  end

  context 'with new navigation previously toggled on' do
    let_it_be(:user) { create(:user, use_new_navigation: true) }

    it 'does not show the callout' do
      expect(page).to have_css('[data-testid="super-sidebar"]')
      expect(page).not_to have_content callout_title
    end
  end

  context 'with new navigation previously toggled off' do
    let_it_be(:user) { create(:user, use_new_navigation: false) }

    it 'shows a callout about the new navigation now being active for everyone' do
      expect(page).to have_css('[data-testid="super-sidebar"]')
      expect(page).to have_content callout_title
    end

    context 'when user dismisses callout' do
      it 'hides callout', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/454405' do
        expect(page).to have_content callout_title

        page.within(find('[data-feature-id="new_nav_for_everyone_callout"]')) do
          find_by_testid('close-icon').click
        end

        wait_for_requests

        visit root_path

        expect(page).not_to have_content callout_title
      end
    end
  end

  context 'with new navigation never toggled on or off' do
    let_it_be(:user) { create(:user, use_new_navigation: nil) }

    it 'does not show the callout' do
      expect(page).to have_css('[data-testid="super-sidebar"]')
      expect(page).not_to have_content callout_title
    end
  end
end

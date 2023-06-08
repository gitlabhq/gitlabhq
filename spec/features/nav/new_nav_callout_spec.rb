# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'new navigation callout', :js, feature_category: :navigation do
  let_it_be(:callout_title) { _('Welcome to a new navigation experience') }
  let(:dot_com) { false }

  before do
    allow(Gitlab).to receive(:com?).and_return(dot_com)
    sign_in(user)
    visit root_path
  end

  context 'with new navigation toggled on' do
    let_it_be(:user) { create(:user, created_at: Date.new(2023, 6, 1), use_new_navigation: true) }

    it 'shows a callout about the new navigation' do
      expect(page).to have_content callout_title
    end

    context 'when user dismisses callout' do
      it 'hides callout' do
        expect(page).to have_content callout_title

        page.within(find('[data-feature-id="new_navigation_callout"]')) do
          find('[data-testid="close-icon"]').click
        end

        wait_for_requests

        visit root_path

        expect(page).not_to have_content callout_title
      end
    end
  end

  context 'when user registered on or after June 2nd 2023' do
    let_it_be(:user) { create(:user, created_at: Date.new(2023, 6, 2), use_new_navigation: true) }

    context 'when on GitLab.com' do
      let(:dot_com) { true }

      it 'does not show the callout about the new navigation' do
        expect(page).not_to have_content callout_title
      end
    end

    context 'when on a self-managed instance' do
      it 'shows the callout about the new navigation' do
        expect(page).to have_content callout_title
      end
    end
  end

  context 'with new navigation toggled off' do
    let_it_be(:user) { create(:user, created_at: Date.new(2023, 6, 1), use_new_navigation: false) }

    it 'does not show the callout' do
      expect(page).not_to have_content callout_title
    end
  end
end

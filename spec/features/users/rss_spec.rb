# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User RSS', feature_category: :user_profile do
  let(:user) { create(:user, :no_super_sidebar) }
  let(:path) { user_path(create(:user, :no_super_sidebar)) }

  describe 'with "user_profile_overflow_menu_vue" feature flag off' do
    before do
      stub_feature_flags(user_profile_overflow_menu_vue: false)
    end

    context 'when signed in' do
      before do
        sign_in(user)
        visit path
      end

      it_behaves_like "it has an RSS button with current_user's feed token"
    end

    context 'when signed out' do
      before do
        visit path
      end

      it_behaves_like "it has an RSS button without a feed token"
    end
  end

  describe 'with "user_profile_overflow_menu_vue" feature flag on', :js do
    context 'when signed in' do
      before do
        sign_in(user)
        visit path
      end

      it 'shows the RSS link with overflow menu' do
        find('[data-testid="base-dropdown-toggle"').click

        expect(page).to have_link 'Subscribe', href: /feed_token=glft-.*-#{user.id}/
      end
    end

    context 'when signed out' do
      before do
        visit path
      end

      it 'has an RSS without a feed token' do
        find('[data-testid="base-dropdown-toggle"').click

        expect(page).not_to have_link 'Subscribe', href: /feed_token=glft-.*-#{user.id}/
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User RSS', feature_category: :user_profile do
  let(:user) { create(:user, :no_super_sidebar) }
  let(:path) { user_path(create(:user, :no_super_sidebar)) }

  context 'when signed in' do
    before do
      sign_in(user)
      visit path
    end

    it 'shows the RSS link with overflow menu', :js do
      find('[data-testid="base-dropdown-toggle"').click

      expect(page).to have_link 'Subscribe', href: /feed_token=glft-.*-#{user.id}/
    end
  end

  context 'when signed out' do
    before do
      stub_feature_flags(super_sidebar_logged_out: false)
      visit path
    end

    it 'has an RSS without a feed token', :js do
      find('[data-testid="base-dropdown-toggle"').click

      expect(page).not_to have_link 'Subscribe', href: /feed_token=glft-.*-#{user.id}/
    end
  end
end

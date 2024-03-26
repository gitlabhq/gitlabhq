# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User RSS', feature_category: :user_profile do
  let(:user) { create(:user) }
  let(:path) { user_path(create(:user)) }

  context 'when signed in' do
    before do
      sign_in(user)
      visit path
    end

    it 'shows the RSS link with overflow menu', :js do
      within_testid('user-profile-header') do
        find_by_testid('base-dropdown-toggle').click
      end

      expect(page).to have_link 'Subscribe', href: /feed_token=glft-.*-#{user.id}/
    end
  end

  context 'when signed out' do
    before do
      visit path
    end

    it 'has an RSS without a feed token', :js do
      within_testid('user-profile-header') do
        find_by_testid('base-dropdown-toggle').click
      end

      expect(page).not_to have_link 'Subscribe', href: /feed_token=glft-.*-#{user.id}/
    end
  end
end

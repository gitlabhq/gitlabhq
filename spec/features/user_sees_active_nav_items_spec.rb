# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User sees correct active nav items in the super sidebar', :js, feature_category: :value_stream_management do
  let_it_be(:current_user) { create(:user) }

  before do
    sign_in(current_user)
  end

  describe 'profile pages' do
    context 'when visiting profile page' do
      before do
        visit user_settings_profile_path
      end

      it 'renders the side navigation with the correct submenu set as active' do
        expect(page).to have_active_sub_navigation('Profile')
      end
    end

    context 'when visiting preferences page' do
      before do
        visit profile_preferences_path
      end

      it 'renders the side navigation with the correct submenu set as active' do
        expect(page).to have_active_sub_navigation('Preferences')
      end
    end

    context 'when visiting authentication logs' do
      before do
        visit user_settings_authentication_log_path
      end

      it 'renders the side navigation with the correct submenu set as active' do
        expect(page).to have_active_sub_navigation('Authentication Log')
      end
    end

    context 'when visiting SSH keys page' do
      before do
        visit user_settings_ssh_keys_path
      end

      it 'renders the side navigation with the correct submenu set as active' do
        expect(page).to have_active_sub_navigation('SSH Keys')
      end
    end

    context 'when visiting account page' do
      before do
        visit profile_account_path
      end

      it 'renders the side navigation with the correct submenu set as active' do
        expect(page).to have_active_sub_navigation('Account')
      end
    end
  end
end

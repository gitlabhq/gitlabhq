# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User uploads avatar to profile', feature_category: :user_profile do
  let!(:user) { create(:user) }
  let(:avatar_file_path) { Rails.root.join('spec', 'fixtures', 'dk.png') }

  shared_examples 'upload avatar' do
    it 'shows the new avatar immediately in the header and setting sidebar', :js do
      expect(page.find('.avatar-image .gl-avatar')['src']).not_to include(
        "/uploads/-/system/user/avatar/#{user.id}/avatar.png"
      )
      find('.js-user-avatar-input', visible: false).set(avatar_file_path)

      click_button 'Set new profile picture'
      click_button 'Update profile settings'

      wait_for_all_requests

      within_testid('user-dropdown') do
        # We are setting a blob URL
        expect(find('.gl-avatar')['src']).to start_with 'blob:'
      end

      visit user_settings_profile_path

      expect(page.find('.avatar-image .gl-avatar')['src']).to include(
        "/uploads/-/system/user/avatar/#{user.id}/avatar.png"
      )
    end
  end

  context 'with "edit_user_profile_vue" turned on' do
    before do
      sign_in_and_visit_profile
    end

    it_behaves_like 'upload avatar'
  end

  context 'with "edit_user_profile_vue" turned off' do
    before do
      stub_feature_flags(edit_user_profile_vue: false)
      sign_in_and_visit_profile
    end

    it 'they see their new avatar on their profile' do
      attach_file('user_avatar', avatar_file_path, visible: false)
      click_button 'Update profile settings'

      visit user_path(user)

      expect(page).to have_selector(%(img[src$="/uploads/-/system/user/avatar/#{user.id}/dk.png?width=192"]))

      # Cheating here to verify something that isn't user-facing, but is important
      expect(user.reload.avatar.file).to exist
    end

    it_behaves_like 'upload avatar'
  end

  private

  def sign_in_and_visit_profile
    sign_in user
    visit user_settings_profile_path
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Upload a user avatar', :js, feature_category: :user_profile do
  let_it_be(:user, reload: true) { create(:user) }

  let(:file) { fixture_file_upload('spec/fixtures/banana_sample.gif') }

  before do
    stub_feature_flags(edit_user_profile_vue: false)
    sign_in(user)
    visit(user_settings_profile_path)
    attach_file('user_avatar-trigger', file.path, make_visible: true)
    click_button 'Set new profile picture'
  end

  subject do
    click_button 'Update profile settings'
  end

  RSpec.shared_examples 'for a user avatar' do
    it 'uploads successfully' do
      expect(user.avatar.file).to eq nil
      subject

      expect(page).to have_content 'Profile was successfully updated'
      expect(user.reload.avatar.file).to be_present
      expect(user.avatar).to be_instance_of AvatarUploader
      expect(page).to have_current_path(user_settings_profile_path, ignore_query: true)
    end
  end

  it_behaves_like 'handling file uploads', 'for a user avatar'
end

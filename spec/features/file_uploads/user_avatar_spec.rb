# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Upload a user avatar', :js do
  let_it_be(:user, reload: true) { create(:user) }

  let(:file) { fixture_file_upload('spec/fixtures/banana_sample.gif') }

  before do
    sign_in(user)
    visit(profile_path)
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
      expect(current_path).to eq(profile_path)
    end
  end

  it_behaves_like 'handling file uploads', 'for a user avatar'
end

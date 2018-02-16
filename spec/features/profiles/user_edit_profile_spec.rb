require 'spec_helper'

describe 'User edit profile' do
  let(:user) { create(:user) }

  before do
    sign_in(user)
    visit(profile_path)
  end

  it 'changes user profile' do
    fill_in 'user_skype', with: 'testskype'
    fill_in 'user_linkedin', with: 'testlinkedin'
    fill_in 'user_twitter', with: 'testtwitter'
    fill_in 'user_website_url', with: 'testurl'
    fill_in 'user_location', with: 'Ukraine'
    fill_in 'user_bio', with: 'I <3 GitLab'
    fill_in 'user_organization', with: 'GitLab'
    click_button 'Update profile settings'

    expect(user.reload).to have_attributes(
      skype: 'testskype',
      linkedin: 'testlinkedin',
      twitter: 'testtwitter',
      website_url: 'testurl',
      bio: 'I <3 GitLab',
      organization: 'GitLab'
    )

    expect(find('#user_location').value).to eq 'Ukraine'
    expect(page).to have_content('Profile was successfully updated')
  end

  context 'user avatar' do
    before do
      attach_file(:user_avatar, Rails.root.join('spec', 'fixtures', 'banana_sample.gif'))
      click_button 'Update profile settings'
    end

    it 'changes user avatar' do
      expect(page).to have_link('Remove avatar')

      user.reload
      expect(user.avatar).to be_instance_of AvatarUploader
      expect(user.avatar.url).to eq "/uploads/-/system/user/avatar/#{user.id}/banana_sample.gif"
    end

    it 'removes user avatar' do
      click_link 'Remove avatar'

      user.reload

      expect(user.avatar?).to eq false
      expect(page).not_to have_link('Remove avatar')
      expect(page).to have_link('gravatar.com')
    end
  end
end

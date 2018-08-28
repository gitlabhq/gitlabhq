require 'spec_helper'

describe 'User edit profile' do
  let(:user) { create(:user) }

  before do
    sign_in(user)
    visit(profile_path)
  end

  def submit_settings
    click_button 'Update profile settings'
  end

  it 'changes user profile' do
    fill_in 'user_skype', with: 'testskype'
    fill_in 'user_linkedin', with: 'testlinkedin'
    fill_in 'user_twitter', with: 'testtwitter'
    fill_in 'user_website_url', with: 'testurl'
    fill_in 'user_location', with: 'Ukraine'
    fill_in 'user_bio', with: 'I <3 GitLab'
    fill_in 'user_organization', with: 'GitLab'
    submit_settings

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
      submit_settings
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

  context 'user status', :js do
    def select_emoji(emoji_name)
      toggle_button = find('.js-toggle-emoji-menu')
      toggle_button.click
      emoji_button = find(%Q{.js-status-emoji-menu .js-emoji-btn gl-emoji[data-name="#{emoji_name}"]})
      emoji_button.click
    end

    it 'shows the user status form' do
      visit(profile_path)

      expect(page).to have_content('Current status')
    end

    it 'adds emoji to user status' do
      emoji = 'biohazard'
      visit(profile_path)
      select_emoji(emoji)
      submit_settings

      visit user_path(user)
      within('.cover-status') do
        expect(page).to have_emoji(emoji)
      end
    end

    it 'adds message to user status' do
      message = 'I have something to say'
      visit(profile_path)
      fill_in 'js-status-message-field', with: message
      submit_settings

      visit user_path(user)
      within('.cover-status') do
        expect(page).to have_emoji('speech_balloon')
        expect(page).to have_content message
      end
    end

    it 'adds message and emoji to user status' do
      emoji = 'tanabata_tree'
      message = 'Playing outside'
      visit(profile_path)
      select_emoji(emoji)
      fill_in 'js-status-message-field', with: message
      submit_settings

      visit user_path(user)
      within('.cover-status') do
        expect(page).to have_emoji(emoji)
        expect(page).to have_content message
      end
    end

    it 'clears the user status' do
      user_status = create(:user_status, user: user, message: 'Eating bread', emoji: 'stuffed_flatbread')

      visit user_path(user)
      within('.cover-status') do
        expect(page).to have_emoji(user_status.emoji)
        expect(page).to have_content user_status.message
      end

      visit(profile_path)
      click_button 'js-clear-user-status-button'
      submit_settings

      visit user_path(user)
      expect(page).not_to have_selector '.cover-status'
    end

    it 'displays a default emoji if only message is entered' do
      message = 'a status without emoji'
      visit(profile_path)
      fill_in 'js-status-message-field', with: message

      within('.js-toggle-emoji-menu') do
        expect(page).to have_emoji('speech_balloon')
      end
    end
  end
end

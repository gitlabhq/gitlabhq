# frozen_string_literal: true

require 'spec_helper'

describe 'User edit profile' do
  let(:user) { create(:user) }

  before do
    sign_in(user)
    visit(profile_path)
  end

  def submit_settings
    click_button 'Update profile settings'
    wait_for_requests if respond_to?(:wait_for_requests)
  end

  it 'changes user profile' do
    fill_in 'user_skype', with: 'testskype'
    fill_in 'user_linkedin', with: 'testlinkedin'
    fill_in 'user_twitter', with: 'testtwitter'
    fill_in 'user_website_url', with: 'testurl'
    fill_in 'user_location', with: 'Ukraine'
    fill_in 'user_bio', with: 'I <3 GitLab'
    fill_in 'user_organization', with: 'GitLab'
    select 'Data Analyst', from: 'user_role'
    submit_settings

    expect(user.reload).to have_attributes(
      skype: 'testskype',
      linkedin: 'testlinkedin',
      twitter: 'testtwitter',
      website_url: 'testurl',
      bio: 'I <3 GitLab',
      organization: 'GitLab',
      role: 'data_analyst'
    )

    expect(find('#user_location').value).to eq 'Ukraine'
    expect(page).to have_content('Profile was successfully updated')
  end

  it 'shows an error if the full name contains an emoji', :js do
    simulate_input('#user_name', 'Martin 😀')
    submit_settings

    page.within('.rspec-full-name') do
      expect(page).to have_css '.gl-field-error-outline'
      expect(find('.gl-field-error')).not_to have_selector('.hidden')
      expect(find('.gl-field-error')).to have_content('Using emojis in names seems fun, but please try to set a status message instead')
    end
  end

  describe 'when I change my email' do
    before do
      user.send_reset_password_instructions
    end

    it 'clears the reset password token' do
      expect(user.reset_password_token?).to be true

      fill_in 'user_email', with: 'new-email@example.com'
      submit_settings

      user.reload
      expect(user.confirmation_token).not_to be_nil
      expect(user.reset_password_token?).to be false
    end
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
    def visit_user
      visit user_path(user)
      wait_for_requests
    end

    def select_emoji(emoji_name, is_modal = false)
      emoji_menu_class = is_modal ? '.js-modal-status-emoji-menu' : '.js-status-emoji-menu'
      toggle_button = find('.js-toggle-emoji-menu')
      toggle_button.click
      emoji_button = find(%Q{#{emoji_menu_class} .js-emoji-btn gl-emoji[data-name="#{emoji_name}"]})
      emoji_button.click
    end

    context 'profile edit form' do
      it 'shows the user status form' do
        expect(page).to have_content('Current status')
      end

      it 'adds emoji to user status' do
        emoji = 'biohazard'
        select_emoji(emoji)
        submit_settings

        visit_user

        within('.cover-status') do
          expect(page).to have_emoji(emoji)
        end
      end

      it 'adds message to user status' do
        message = 'I have something to say'
        fill_in 'js-status-message-field', with: message
        submit_settings

        visit_user

        within('.cover-status') do
          expect(page).to have_emoji('speech_balloon')
          expect(page).to have_content message
        end
      end

      it 'adds message and emoji to user status' do
        emoji = 'tanabata_tree'
        message = 'Playing outside'
        select_emoji(emoji)
        fill_in 'js-status-message-field', with: message
        submit_settings

        visit_user

        within('.cover-status') do
          expect(page).to have_emoji(emoji)
          expect(page).to have_content message
        end
      end

      it 'clears the user status' do
        user_status = create(:user_status, user: user, message: 'Eating bread', emoji: 'stuffed_flatbread')

        visit_user

        within('.cover-status') do
          expect(page).to have_emoji(user_status.emoji)
          expect(page).to have_content user_status.message
        end

        visit(profile_path)
        click_button 'js-clear-user-status-button'
        submit_settings

        visit_user

        expect(page).not_to have_selector '.cover-status'
      end

      it 'displays a default emoji if only message is entered' do
        message = 'a status without emoji'
        fill_in 'js-status-message-field', with: message

        within('.js-toggle-emoji-menu') do
          expect(page).to have_emoji('speech_balloon')
        end
      end
    end

    context 'user menu' do
      let(:issue) { create(:issue, project: project)}
      let(:project) { create(:project) }

      def open_user_status_modal
        find('.header-user-dropdown-toggle').click

        page.within ".header-user" do
          click_button 'Set status'
        end
      end

      def set_user_status_in_modal
        page.within "#set-user-status-modal" do
          click_button 'Set status'
        end
        wait_for_requests
      end

      before do
        visit root_path(user)
      end

      it 'shows the "Set status" menu item in the user menu' do
        find('.header-user-dropdown-toggle').click

        page.within ".header-user" do
          expect(page).to have_content('Set status')
        end
      end

      it 'shows the "Edit status" menu item in the user menu' do
        user_status = create(:user_status, user: user, message: 'Eating bread', emoji: 'stuffed_flatbread')
        visit root_path(user)

        find('.header-user-dropdown-toggle').click

        page.within ".header-user" do
          expect(page).to have_emoji(user_status.emoji)
          expect(page).to have_content user_status.message
          expect(page).to have_content('Edit status')
        end
      end

      it 'shows user status modal' do
        open_user_status_modal

        expect(page.find('#set-user-status-modal')).to be_visible
        expect(page).to have_content('Set a status')
      end

      it 'adds emoji to user status' do
        emoji = 'biohazard'
        open_user_status_modal
        select_emoji(emoji, true)
        set_user_status_in_modal

        visit_user

        within('.cover-status') do
          expect(page).to have_emoji(emoji)
        end
      end

      it 'does not update the awards panel emoji' do
        project.add_maintainer(user)
        visit(project_issue_path(project, issue))

        emoji = 'biohazard'
        open_user_status_modal
        select_emoji(emoji, true)

        expect(page.all('.award-control .js-counter')).to all(have_content('0'))
      end

      it 'adds message to user status' do
        message = 'I have something to say'
        open_user_status_modal
        find('.js-status-message-field').native.send_keys(message)
        set_user_status_in_modal

        visit_user

        within('.cover-status') do
          expect(page).to have_emoji('speech_balloon')
          expect(page).to have_content message
        end
      end

      it 'adds message and emoji to user status' do
        emoji = 'tanabata_tree'
        message = 'Playing outside'
        open_user_status_modal
        select_emoji(emoji, true)
        find('.js-status-message-field').native.send_keys(message)
        set_user_status_in_modal

        visit_user

        within('.cover-status') do
          expect(page).to have_emoji(emoji)
          expect(page).to have_content message
        end
      end

      it 'clears the user status with the "X" button' do
        user_status = create(:user_status, user: user, message: 'Eating bread', emoji: 'stuffed_flatbread')

        visit_user
        wait_for_requests

        within('.cover-status') do
          expect(page).to have_emoji(user_status.emoji)
          expect(page).to have_content user_status.message
        end

        find('.header-user-dropdown-toggle').click

        page.within ".header-user" do
          click_button 'Edit status'
        end

        find('.js-clear-user-status-button').click
        set_user_status_in_modal

        visit_user
        wait_for_requests

        expect(page).not_to have_selector '.cover-status'
      end

      it 'clears the user status with the "Remove status" button' do
        user_status = create(:user_status, user: user, message: 'Eating bread', emoji: 'stuffed_flatbread')

        visit_user
        wait_for_requests

        within('.cover-status') do
          expect(page).to have_emoji(user_status.emoji)
          expect(page).to have_content user_status.message
        end

        find('.header-user-dropdown-toggle').click

        page.within ".header-user" do
          click_button 'Edit status'
        end

        page.within "#set-user-status-modal" do
          click_button 'Remove status'
        end

        visit_user

        expect(page).not_to have_selector '.cover-status'
      end

      it 'displays a default emoji if only message is entered' do
        message = 'a status without emoji'
        open_user_status_modal
        find('.js-status-message-field').native.send_keys(message)

        within('.js-toggle-emoji-menu') do
          expect(page).to have_emoji('speech_balloon')
        end
      end
    end

    context 'User time preferences', :js do
      let(:issue) { create(:issue, project: project)}
      let(:project) { create(:project) }

      before do
        stub_feature_flags(user_time_settings: true)
      end

      it 'shows the user time preferences form' do
        expect(page).to have_content('Time settings')
      end

      it 'allows the user to select a time zone from a dropdown list of options' do
        expect(page.find('.user-time-preferences .dropdown')).not_to have_css('.show')

        page.find('.user-time-preferences .js-timezone-dropdown').click

        expect(page.find('.user-time-preferences .dropdown')).to have_css('.show')

        page.find("a", text: "Nuku'alofa").click

        tz = page.find('.user-time-preferences #user_timezone', visible: false)

        expect(tz.value).to eq('Pacific/Tongatapu')
      end

      it 'timezone defaults to servers default' do
        timezone_name = Time.zone.tzinfo.name
        expect(page.find('.user-time-preferences #user_timezone', visible: false).value).to eq(timezone_name)
      end
    end
  end
end

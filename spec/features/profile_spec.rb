require 'spec_helper'

describe 'Profile account page' do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe 'when signup is enabled' do
    before do
      stub_application_setting(signup_enabled: true)
      visit profile_account_path
    end

    it { expect(page).to have_content('Remove account') }

    it 'deletes the account' do
      expect { click_link 'Delete account' }.to change { User.where(id: user.id).count }.by(-1)
      expect(current_path).to eq(new_user_session_path)
    end
  end

  describe 'when signup is disabled' do
    before do
      stub_application_setting(signup_enabled: false)
      visit profile_account_path
    end

    it 'does not have option to remove account' do
      expect(page).not_to have_content('Remove account')
      expect(current_path).to eq(profile_account_path)
    end
  end

  describe 'when I reset private token' do
    before do
      visit profile_account_path
    end

    it 'resets private token' do
      previous_token = find("#private-token").value

      click_link('Reset private token')

      expect(find('#private-token').value).not_to eq(previous_token)
    end
  end

  describe 'when I reset RSS token' do
    before do
      visit profile_account_path
    end

    it 'resets RSS token' do
      previous_token = find("#rss-token").value

      click_link('Reset RSS token')

      expect(page).to have_content 'RSS token was successfully reset'
      expect(find('#rss-token').value).not_to eq(previous_token)
    end
  end

  describe 'when I reset incoming email token' do
    before do
      allow(Gitlab.config.incoming_email).to receive(:enabled).and_return(true)
      visit profile_account_path
    end

    it 'resets incoming email token' do
      previous_token = find('#incoming-email-token').value

      click_link('Reset incoming email token')

      expect(find('#incoming-email-token').value).not_to eq(previous_token)
    end
  end

  describe 'when I change my username' do
    before do
      visit profile_account_path
    end

    it 'changes my username' do
      fill_in 'user_username', with: 'new-username'

      click_button('Update username')

      expect(page).to have_content('new-username')
    end
  end
end

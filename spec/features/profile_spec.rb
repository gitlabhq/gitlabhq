require 'spec_helper'

describe 'Profile account page', feature: true do
  let(:user) { create(:user) }

  before do
    login_as :user
  end

  describe 'when signup is enabled' do
    before do
      stub_application_setting(signup_enabled: true)
      visit profile_account_path
    end

    it { expect(page).to have_content('Remove account') }

    it 'should delete the account' do
      expect { click_link 'Delete account' }.to change { User.count }.by(-1)
      expect(current_path).to eq(new_user_session_path)
    end
  end

  describe 'when signup is disabled' do
    before do
      stub_application_setting(signup_enabled: false)
      visit profile_account_path
    end

    it 'should not have option to remove account' do
      expect(page).not_to have_content('Remove account')
      expect(current_path).to eq(profile_account_path)
    end
  end
end

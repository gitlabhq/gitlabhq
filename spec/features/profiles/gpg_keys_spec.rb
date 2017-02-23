require 'rails_helper'

feature 'Profile > GPG Keys', :gpg do
  let(:user) { create(:user) }

  before do
    login_as(user)
  end

  describe 'User adds a key' do
    before do
      visit profile_gpg_keys_path
    end

    scenario 'saves the new key' do
      fill_in('Key', with: attributes_for(:gpg_key)[:key])
      click_button('Add key')

      expect(page).to have_content(GpgHelpers::User1.email)
      expect(page).to have_content(GpgHelpers::User1.fingerprint)
    end
  end

  scenario 'User sees their keys' do
    create(:gpg_key, user: user)
    visit profile_gpg_keys_path

    expect(page).to have_content(GpgHelpers::User1.email)
    expect(page).to have_content(GpgHelpers::User1.fingerprint)
  end

  scenario 'User removes a key via the key index' do
    create(:gpg_key, user: user)
    visit profile_gpg_keys_path

    click_link('Remove')

    expect(page).to have_content('Your GPG keys (0)')
  end
end

require 'rails_helper'

feature 'Profile > GPG Keys' do
  let(:user) { create(:user, email: GpgHelpers::User2.emails.first) }

  before do
    sign_in(user)
  end

  describe 'User adds a key' do
    before do
      visit profile_gpg_keys_path
    end

    scenario 'saves the new key' do
      fill_in('Key', with: GpgHelpers::User2.public_key)
      click_button('Add key')

      expect(page).to have_content('bette.cartwright@example.com Verified')
      expect(page).to have_content('bette.cartwright@example.net Unverified')
      expect(page).to have_content(GpgHelpers::User2.fingerprint)
    end

    scenario 'with multiple subkeys' do
      fill_in('Key', with: GpgHelpers::User3.public_key)
      click_button('Add key')

      expect(page).to have_content('john.doe@example.com Unverified')
      expect(page).to have_content(GpgHelpers::User3.fingerprint)

      GpgHelpers::User3.subkey_fingerprints.each do |fingerprint|
        expect(page).to have_content(fingerprint)
      end
    end
  end

  scenario 'User sees their key' do
    create(:gpg_key, user: user, key: GpgHelpers::User2.public_key)
    visit profile_gpg_keys_path

    expect(page).to have_content('bette.cartwright@example.com Verified')
    expect(page).to have_content('bette.cartwright@example.net Unverified')
    expect(page).to have_content(GpgHelpers::User2.fingerprint)
  end

  scenario 'User removes a key via the key index' do
    create(:gpg_key, user: user, key: GpgHelpers::User2.public_key)
    visit profile_gpg_keys_path

    click_link('Remove')

    expect(page).to have_content('Your GPG keys (0)')
  end

  scenario 'User revokes a key via the key index' do
    gpg_key = create :gpg_key, user: user, key: GpgHelpers::User2.public_key
    gpg_signature = create :gpg_signature, gpg_key: gpg_key, verification_status: :verified

    visit profile_gpg_keys_path

    click_link('Revoke')

    expect(page).to have_content('Your GPG keys (0)')

    expect(gpg_signature.reload).to have_attributes(
      verification_status: 'unknown_key',
      gpg_key: nil
    )
  end
end

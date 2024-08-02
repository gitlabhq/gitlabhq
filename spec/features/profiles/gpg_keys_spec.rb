# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'User Settings > GPG Keys', feature_category: :user_profile do
  let(:user) { create(:user, email: GpgHelpers::User2.emails.first) }

  before do
    sign_in(user)
  end

  describe 'User adds a key' do
    before do
      visit user_settings_gpg_keys_path
    end

    it 'saves the new key' do
      click_button('Add new key')
      fill_in('Key', with: GpgHelpers::User2.public_key)
      click_button('Add key')

      expect(page).to have_content('bette.cartwright@example.com Verified')
      expect(page).to have_content('bette.cartwright@example.net Unverified')
      expect(page).to have_content(GpgHelpers::User2.fingerprint)
    end

    it 'with multiple subkeys' do
      click_button('Add new key')
      fill_in('Key', with: GpgHelpers::User3.public_key)
      click_button('Add key')

      expect(page).to have_content('john.doe@example.com Unverified')
      expect(page).to have_content(GpgHelpers::User3.fingerprint)

      GpgHelpers::User3.subkey_fingerprints.each do |fingerprint|
        expect(page).to have_content(fingerprint)
      end
    end
  end

  it 'user sees their key' do
    gpg_key = create(:gpg_key, user: user, key: GpgHelpers::User2.public_key)
    visit user_settings_gpg_keys_path

    expect(page).to have_content('bette.cartwright@example.com Verified')
    expect(page).to have_content('bette.cartwright@example.net Unverified')
    expect(page).to have_content(GpgHelpers::User2.fingerprint)
    expect(page).to have_selector('time.js-timeago', text: gpg_key.created_at.strftime('%b %d, %Y'))
  end

  it 'user removes a key via the key index' do
    create(:gpg_key, user: user, key: GpgHelpers::User2.public_key)
    visit user_settings_gpg_keys_path

    click_link('Remove')

    expect(page).to have_content('Your GPG keys')
    within_testid('crud-count') do
      expect(page).to have_content('0')
    end
  end

  it 'user revokes a key via the key index' do
    gpg_key = create :gpg_key, user: user, key: GpgHelpers::User2.public_key
    gpg_signature = create :gpg_signature, gpg_key: gpg_key, verification_status: :verified

    visit user_settings_gpg_keys_path

    click_link('Revoke')

    expect(page).to have_content('Your GPG keys')
    within_testid('crud-count') do
      expect(page).to have_content('0')
    end

    expect(gpg_signature.reload).to have_attributes(
      verification_status: 'unknown_key',
      gpg_key: nil
    )
  end

  context 'when external verification is required' do
    let!(:beyond_identity_integration) { create(:beyond_identity_integration) }
    let!(:gpg_key) do
      create :gpg_key, externally_verified: externally_verified, user: user, key: GpgHelpers::User2.public_key
    end

    before do
      visit user_settings_gpg_keys_path
    end

    context 'and user has a key that is externally verified' do
      let(:externally_verified) { true }

      it 'considers the key Verified' do
        expect(page).to have_content('bette.cartwright@example.com Verified')
      end
    end

    context 'and user has a key that is not externally verified' do
      let(:externally_verified) { false }

      it 'considers the key Unverified' do
        expect(page).not_to have_content('bette.cartwright@example.com')
        expect(page).not_to have_content('Verified')
        expect(page).not_to have_content('Unverified')
      end
    end
  end
end

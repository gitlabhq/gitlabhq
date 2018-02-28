require 'rails_helper'

feature 'Profile > SSH Keys' do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe 'User adds a key' do
    before do
      visit profile_keys_path
    end

    scenario 'auto-populates the title', :js do
      fill_in('Key', with: attributes_for(:key).fetch(:key))

      expect(page).to have_field("Title", with: "dummy@gitlab.com")
    end

    scenario 'saves the new key' do
      attrs = attributes_for(:key)

      fill_in('Key', with: attrs[:key])
      fill_in('Title', with: attrs[:title])
      click_button('Add key')

      expect(page).to have_content("Title: #{attrs[:title]}")
      expect(page).to have_content(attrs[:key])
      expect(find('.breadcrumbs-sub-title')).to have_link(attrs[:title])
    end

    context 'when only DSA and ECDSA keys are allowed' do
      before do
        forbidden = ApplicationSetting::FORBIDDEN_KEY_VALUE
        stub_application_setting(rsa_key_restriction: forbidden, ed25519_key_restriction: forbidden)
      end

      scenario 'shows a validation error' do
        attrs = attributes_for(:key)

        fill_in('Key', with: attrs[:key])
        fill_in('Title', with: attrs[:title])
        click_button('Add key')

        expect(page).to have_content('Key type is forbidden. Must be DSA or ECDSA')
      end
    end
  end

  scenario 'User sees their keys' do
    key = create(:key, user: user)
    visit profile_keys_path

    expect(page).to have_content(key.title)
  end

  scenario 'User removes a key via the key index' do
    create(:key, user: user)
    visit profile_keys_path

    click_link('Remove')

    expect(page).to have_content('Your SSH keys (0)')
  end

  scenario 'User removes a key via its details page' do
    key = create(:key, user: user)
    visit profile_key_path(key)

    click_link('Remove')

    expect(page).to have_content('Your SSH keys (0)')
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Profile > SSH Keys' do
  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe 'User adds a key' do
    before do
      visit profile_keys_path
    end

    it 'auto-populates the title', :js do
      fill_in('Key', with: attributes_for(:key).fetch(:key))

      expect(page).to have_field("Title", with: "dummy@gitlab.com")
    end

    it 'saves the new key' do
      attrs = attributes_for(:key)

      fill_in('Key', with: attrs[:key])
      fill_in('Title', with: attrs[:title])
      click_button('Add key')

      expect(page).to have_content("Title: #{attrs[:title]}")
      expect(page).to have_content(attrs[:key])
      expect(find('.breadcrumbs-sub-title')).to have_link(attrs[:title])
    end

    it 'shows a confirmable warning if the key does not start with ssh-' do
      attrs = attributes_for(:key)

      fill_in('Key', with: 'invalid-key')
      fill_in('Title', with: attrs[:title])
      click_button('Add key')

      expect(page).to have_selector('.js-add-ssh-key-validation-warning')

      find('.js-add-ssh-key-validation-confirm-submit').click

      expect(page).to have_content('Key is invalid')
    end

    context 'when only DSA and ECDSA keys are allowed' do
      before do
        forbidden = ApplicationSetting::FORBIDDEN_KEY_VALUE
        stub_application_setting(rsa_key_restriction: forbidden, ed25519_key_restriction: forbidden)
      end

      it 'shows a validation error' do
        attrs = attributes_for(:key)

        fill_in('Key', with: attrs[:key])
        fill_in('Title', with: attrs[:title])
        click_button('Add key')

        expect(page).to have_content('Key type is forbidden. Must be DSA or ECDSA')
      end
    end
  end

  it 'User sees their keys' do
    key = create(:key, user: user)
    visit profile_keys_path

    expect(page).to have_content(key.title)
  end

  describe 'User removes a key', :js do
    shared_examples 'removes key' do
      it 'removes key' do
        visit path
        click_button('Delete')

        page.within('.modal') do
          page.click_button('Delete')
        end

        expect(page).to have_content('Your SSH keys (0)')
      end
    end

    context 'via the key index' do
      before do
        create(:key, user: user)
      end

      let(:path) { profile_keys_path }

      it_behaves_like 'removes key'
    end

    context 'via its details page' do
      let(:key) { create(:key, user: user) }
      let(:path) { profile_keys_path(key) }

      it_behaves_like 'removes key'
    end
  end
end

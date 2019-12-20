# frozen_string_literal: true

require 'spec_helper'

describe 'User creates snippet', :js do
  let(:user) { create(:user) }

  before do
    stub_feature_flags(allow_possible_spam: false)
    stub_feature_flags(snippets_vue: false)
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')

    Gitlab::CurrentSettings.update!(
      akismet_enabled: true,
      akismet_api_key: 'testkey',
      recaptcha_enabled: true,
      recaptcha_site_key: 'test site key',
      recaptcha_private_key: 'test private key'
    )

    sign_in(user)
    visit new_snippet_path

    fill_in 'personal_snippet_title', with: 'My Snippet Title'
    fill_in 'personal_snippet_description', with: 'My Snippet **Description**'
    find('#personal_snippet_visibility_level_20').set(true)
    page.within('.file-editor') do
      find('.ace_text-input', visible: false).send_keys 'Hello World!'
    end
  end

  shared_examples 'solve recaptcha' do
    it 'creates a snippet after solving reCaptcha' do
      click_button('Create snippet')
      wait_for_requests

      # it is impossible to test recaptcha automatically and there is no possibility to fill in recaptcha
      # recaptcha verification is skipped in test environment and it always returns true
      expect(page).not_to have_content('My Snippet Title')
      expect(page).to have_css('.recaptcha')
      click_button('Submit personal snippet')

      expect(page).to have_content('My Snippet Title')
    end
  end

  context 'when identified as a spam' do
    before do
      WebMock.stub_request(:any, /.*akismet.com.*/).to_return(body: "true", status: 200)
    end

    context 'when allow_possible_spam feature flag is false' do
      it_behaves_like 'solve recaptcha'
    end

    context 'when allow_possible_spam feature flag is true' do
      it_behaves_like 'solve recaptcha'
    end
  end

  context 'when not identified as a spam' do
    before do
      WebMock.stub_request(:any, /.*akismet.com.*/).to_return(body: "false", status: 200)
    end

    it 'creates a snippet' do
      click_button('Create snippet')
      wait_for_requests

      expect(page).not_to have_css('.recaptcha')
      expect(page).to have_content('My Snippet Title')
    end
  end
end

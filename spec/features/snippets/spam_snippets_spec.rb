# frozen_string_literal: true

require 'spec_helper'

shared_examples_for 'snippet editor' do
  include_context 'includes Spam constants'

  def description_field
    find('.js-description-input').find('input,textarea')
  end

  before do
    stub_feature_flags(allow_possible_spam: false)
    stub_feature_flags(snippets_vue: false)
    stub_feature_flags(snippets_edit_vue: false)
    stub_feature_flags(monaco_snippets: flag)
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

    # Click placeholder first to expand full description field
    description_field.click
    fill_in 'personal_snippet_description', with: 'My Snippet **Description**'

    find('#personal_snippet_visibility_level_20').set(true)
    page.within('.file-editor') do
      el = flag == true ? find('.inputarea') : find('.ace_text-input', visible: false)
      el.send_keys 'Hello World!'
    end
  end

  shared_examples 'solve reCAPTCHA' do
    it 'creates a snippet after solving reCAPTCHA' do
      click_button('Create snippet')
      wait_for_requests

      # it is impossible to test reCAPTCHA automatically and there is no possibility to fill in recaptcha
      # reCAPTCHA verification is skipped in test environment and it always returns true
      expect(page).not_to have_content('My Snippet Title')
      expect(page).to have_css('.recaptcha')
      click_button('Submit personal snippet')

      expect(page).to have_content('My Snippet Title')
    end
  end

  shared_examples 'does not allow creation' do
    it 'rejects creation of the snippet' do
      click_button('Create snippet')
      wait_for_requests

      expect(page).to have_content('discarded')
      expect(page).not_to have_content('My Snippet Title')
      expect(page).not_to have_css('.recaptcha')
    end
  end

  context 'when SpamVerdictService requires recaptcha' do
    before do
      expect_next_instance_of(Spam::SpamVerdictService) do |verdict_service|
        expect(verdict_service).to receive(:execute).and_return(REQUIRE_RECAPTCHA)
      end
    end

    context 'when allow_possible_spam feature flag is false' do
      before do
        stub_application_setting(recaptcha_enabled: false)
      end

      it_behaves_like 'does not allow creation'
    end

    context 'when allow_possible_spam feature flag is true' do
      it_behaves_like 'solve reCAPTCHA'
    end
  end

  context 'when SpamVerdictService disallows' do
    before do
      expect_next_instance_of(Spam::SpamVerdictService) do |verdict_service|
        expect(verdict_service).to receive(:execute).and_return(DISALLOW)
      end
    end

    context 'when allow_possible_spam feature flag is false' do
      before do
        stub_application_setting(recaptcha_enabled: false)
      end

      it_behaves_like 'does not allow creation'
    end

    context 'when allow_possible_spam feature flag is true' do
      it_behaves_like 'does not allow creation'
    end
  end

  context 'when SpamVerdictService allows' do
    before do
      expect_next_instance_of(Spam::SpamVerdictService) do |verdict_service|
        expect(verdict_service).to receive(:execute).and_return(ALLOW)
      end
    end

    it 'creates a snippet' do
      click_button('Create snippet')
      wait_for_requests

      expect(page).not_to have_css('.recaptcha')
      expect(page).to have_content('My Snippet Title')
    end
  end
end

describe 'User creates snippet', :js do
  let_it_be(:user) { create(:user) }

  context 'when using Monaco' do
    it_behaves_like "snippet editor" do
      let(:flag) { true }
    end
  end

  context 'when using ACE' do
    it_behaves_like "snippet editor" do
      let(:flag) { false }
    end
  end
end

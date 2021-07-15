# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Help Pages' do
  describe 'Get the main help page' do
    before do
      allow(File).to receive(:read).and_call_original
      allow(File).to receive(:read).with(Rails.root.join('doc', 'README.md')).and_return(fixture_file('sample_doc.md'))
    end

    context 'quick link shortcuts', :js do
      before do
        visit help_path
      end

      it 'focuses search bar' do
        find('.js-trigger-search-bar').click

        expect(page).to have_selector('#search:focus')
      end

      it 'opens shortcuts help dialog' do
        find('.js-trigger-shortcut').click

        expect(page).to have_selector('[data-testid="modal-shortcuts"]')
      end
    end
  end

  context 'in a production environment with version check enabled' do
    before do
      stub_application_setting(version_check_enabled: true)

      stub_rails_env('production')
      allow(VersionCheck).to receive(:url).and_return('/version-check-url')

      sign_in(create(:user))
      visit help_path
    end

    it 'has a version check image' do
      # Check `data-src` due to lazy image loading
      expect(find('.js-version-status-badge', visible: false)['data-src'])
        .to end_with('/version-check-url')
    end
  end

  describe 'when help page is customized' do
    before do
      stub_application_setting(help_page_hide_commercial_content: true,
                               help_page_text: 'My Custom Text',
                               help_page_support_url: 'http://example.com/help')

      sign_in(create(:user))
      visit help_path
    end

    it 'displays custom help page text' do
      expect(page).to have_text "My Custom Text"
    end

    it 'hides marketing content when enabled' do
      expect(page).not_to have_link "Get a support subscription"
    end

    it 'uses a custom support url' do
      expect(page).to have_link "See our website for help", href: "http://example.com/help"
    end
  end
end

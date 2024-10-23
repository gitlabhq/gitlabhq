# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Help Pages', feature_category: :shared do
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

  describe 'with version check enabled' do
    let_it_be(:user) { create(:user) }

    before do
      stub_application_setting(version_check_enabled: true)
      allow(User).to receive(:single_user).and_return(double(user, requires_usage_stats_consent?: false))
      allow(user).to receive(:can_admin_all_resources?).and_return(true)

      sign_in(user)
      visit help_path
    end

    it 'renders the version check badge' do
      expect(page).to have_selector('.js-gitlab-version-check-badge')
    end
  end

  describe 'when help page is customized' do
    before do
      stub_application_setting(
        help_page_hide_commercial_content: true,
        help_page_text: 'My Custom Text',
        help_page_support_url: 'http://example.com/help'
      )

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

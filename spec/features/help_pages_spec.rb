require 'spec_helper'

describe 'Help Pages' do
  describe 'Get the main help page' do
    shared_examples_for 'help page' do |prefix: ''|
      it 'prefixes links correctly' do
        expect(page).to have_selector(%(div.documentation-index > ul a[href="#{prefix}/help/api/README.md"]))
      end
    end

    context 'without a trailing slash' do
      before do
        visit help_path
      end

      it_behaves_like 'help page'
    end

    context 'with a trailing slash' do
      before do
        visit help_path + '/'
      end

      it_behaves_like 'help page'
    end

    context 'with a relative installation' do
      before do
        stub_config_setting(relative_url_root: '/gitlab')
        visit help_path
      end

      it_behaves_like 'help page', prefix: '/gitlab'
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

        expect(page).to have_selector('#modal-shortcuts')
      end
    end
  end

  context 'in a production environment with version check enabled', :js do
    before do
      allow(Rails.env).to receive(:production?) { true }
      stub_application_setting(version_check_enabled: true)
      allow_any_instance_of(VersionCheck).to receive(:url) { '/version-check-url' }

      sign_in(create(:user))
      visit help_path
    end

    it 'has a version check image' do
      expect(find('.js-version-status-badge', visible: false)['src']).to end_with('/version-check-url')
    end

    it 'hides the version check image if the image request fails' do
      # We use '--load-images=yes' with poltergeist so the image fails to load
      expect(page).to have_selector('.js-version-status-badge', visible: false)
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

    it 'should display custom help page text' do
      expect(page).to have_text "My Custom Text"
    end

    it 'should hide marketing content when enabled' do
      expect(page).not_to have_link "Get a support subscription"
    end

    it 'should use a custom support url' do
      expect(page).to have_link "See our website for getting help", href: "http://example.com/help"
    end
  end
end

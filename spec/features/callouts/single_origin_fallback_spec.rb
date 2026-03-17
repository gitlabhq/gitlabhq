# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Single origin fallback callout', :do_not_mock_admin_mode_setting, feature_category: :web_ide do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:non_admin) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:callout_title) { _('Web IDE single origin fallback is enabled') }

  context 'when single origin fallback is enabled' do
    before do
      Gitlab::CurrentSettings.update!(vscode_extension_marketplace: {
        enabled: true,
        single_origin_fallback_enabled: true,
        extension_host_domain: 'cdn.web-ide.gitlab-static.net'
      })
    end

    context 'when an admin is logged in' do
      before do
        sign_in(admin)
      end

      it 'displays callout in home page' do
        visit admin_root_path

        expect(page).to have_content callout_title
        expect(page).to have_link _('Review settings'),
          href: general_admin_application_settings_path(anchor: 'js-web-ide-settings')
      end

      it 'does not display callout on pages other than admin settings' do
        visit project_issues_path(project)

        expect(page).not_to have_content callout_title
      end

      context 'when callout is dismissed', :js do
        before do
          visit root_path

          within('body.page-initialised') do
            find_by_testid('close-single-origin-fallback-callout').click
          end

          wait_for_requests

          visit root_path
        end

        it 'does not display callout' do
          expect(page).not_to have_content callout_title
        end
      end
    end

    context 'when a non-admin is logged in' do
      before do
        sign_in(non_admin)
      end

      it 'does not display callout' do
        visit root_path

        expect(page).not_to have_content callout_title
      end
    end
  end

  context 'when single origin fallback is disabled' do
    before do
      Gitlab::CurrentSettings.update!(vscode_extension_marketplace: {
        enabled: true,
        single_origin_fallback_enabled: false
      })
      sign_in(admin)
    end

    it 'does not display callout' do
      visit root_path

      expect(page).not_to have_content callout_title
    end
  end
end

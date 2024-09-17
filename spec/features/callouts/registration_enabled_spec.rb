# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Registration enabled callout', feature_category: :system_access do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:non_admin) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:callout_title) { _('Check your sign-up restrictions') }

  context 'when "Sign-up enabled" setting is `true`' do
    before do
      stub_application_setting(signup_enabled: true)
    end

    context 'when an admin is logged in', :do_not_mock_admin_mode_setting do
      before do
        sign_in(admin)
      end

      it 'displays callout on admin and dashboard pages and root page' do
        visit root_path

        expect(page).to have_content callout_title
        expect(page).to have_link _('Deactivate'), href: general_admin_application_settings_path(anchor: 'js-signup-settings')

        visit root_dashboard_path

        expect(page).to have_content callout_title

        visit admin_root_path

        expect(page).to have_content callout_title
      end

      it 'does not display callout on pages other than root, admin, or dashboard' do
        visit project_issues_path(project)

        expect(page).not_to have_content callout_title
      end

      context 'when callout is dismissed', :js do
        before do
          visit admin_root_path

          within('body.page-initialised') do
            find_by_testid('close-registration-enabled-callout').click
          end

          wait_for_requests

          visit root_dashboard_path
        end

        it 'does not display callout' do
          expect(page).not_to have_content callout_title
        end
      end
    end

    context 'when a non-admin is logged in' do
      before do
        sign_in(non_admin)
        visit root_dashboard_path
      end

      it 'does not display callout' do
        expect(page).not_to have_content callout_title
      end
    end
  end
end

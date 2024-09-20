# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'OpenSSL callout', :do_not_mock_admin_mode_setting, feature_category: :system_access do
  include StubVersion
  let_it_be(:admin) { create(:admin) }
  let_it_be(:non_admin) { create(:user) }
  let_it_be(:callout_title) { _('OpenSSL version 3') }

  context 'when GitLab version is >= 17.1 and < 17.7' do
    before do
      stub_version('17.4.99', 'abcdefg')
    end

    context 'when an admin is logged in' do
      before do
        sign_in(admin)
      end

      it 'displays callout on admin area' do
        visit admin_root_path

        expect(page).to have_content callout_title
        expect(page).to have_button _('Acknowledge')

        visit admin_users_path

        expect(page).to have_content callout_title
      end

      it 'does not display callout on pages other than the admin area' do
        visit root_dashboard_path

        expect(page).not_to have_content callout_title
      end

      context 'when callout is dismissed', :js do
        before do
          visit admin_root_path

          within('body.page-initialised') do
            find_by_testid('close-openssl-callout').click
          end

          wait_for_requests

          visit admin_users_path
        end

        it 'does not display callout' do
          expect(page).not_to have_content callout_title
        end
      end
    end

    context 'when a non-admin is logged in' do
      before do
        sign_in(non_admin)
        visit admin_root_path
      end

      it 'does not display callout' do
        expect(page).not_to have_content callout_title
      end
    end
  end

  context 'when GitLab version is >= 17.7' do
    before do
      stub_version('17.7.0', 'abcdefg')
      sign_in(admin)
    end

    it 'does not display the callout' do
      visit admin_root_path

      expect(page).not_to have_content callout_title
    end
  end
end

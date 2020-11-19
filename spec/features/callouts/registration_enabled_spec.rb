# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Registration enabled callout' do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:non_admin) { create(:user) }

  context 'when "Sign-up enabled" setting is `true`' do
    before do
      stub_application_setting(signup_enabled: true)
    end

    context 'when an admin is logged in' do
      before do
        sign_in(admin)
        visit root_dashboard_path
      end

      it 'displays callout' do
        expect(page).to have_content 'Open registration is enabled on your instance.'
        expect(page).to have_link 'View setting', href: general_admin_application_settings_path(anchor: 'js-signup-settings')
      end

      context 'when callout is dismissed', :js do
        before do
          find('[data-testid="close-registration-enabled-callout"]').click

          visit root_dashboard_path
        end

        it 'does not display callout' do
          expect(page).not_to have_content 'Open registration is enabled on your instance.'
        end
      end
    end

    context 'when a non-admin is logged in' do
      before do
        sign_in(non_admin)
        visit root_dashboard_path
      end

      it 'does not display callout' do
        expect(page).not_to have_content 'Open registration is enabled on your instance.'
      end
    end
  end
end

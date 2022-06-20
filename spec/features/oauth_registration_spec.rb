# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'OAuth Registration', :js, :allow_forgery_protection do
  include DeviseHelpers
  include LoginHelpers
  include TermsHelper
  using RSpec::Parameterized::TableSyntax

  around do |example|
    with_omniauth_full_host { example.run }
  end

  context 'when the user registers using single-sign on provider' do
    let(:uid) { 'my-uid' }
    let(:email) { 'user@example.com' }

    where(:provider, :additional_info) do
      :github         | {}
      :twitter        | {}
      :bitbucket      | {}
      :gitlab         | {}
      :google_oauth2  | {}
      :facebook       | {}
      :cas3           | {}
      :auth0          | {}
      :authentiq      | {}
      :salesforce     | { extra: { email_verified: true } }
      :dingtalk       | {}
      :alicloud       | {}
    end

    with_them do
      before do
        stub_omniauth_provider(provider)
        stub_feature_flags(update_oauth_registration_flow: true)
      end

      context 'when block_auto_created_users is true' do
        before do
          stub_omniauth_setting(block_auto_created_users: true)
        end

        it 'redirects back to the sign-in page' do
          register_via(provider, uid, email, additional_info: additional_info)

          expect(page).to have_current_path new_user_session_path
          expect(page).to have_content('Your account is pending approval')
        end
      end

      context 'when block_auto_created_users is false' do
        before do
          stub_omniauth_setting(block_auto_created_users: false)
        end

        it 'redirects to the initial welcome path' do
          register_via(provider, uid, email, additional_info: additional_info)

          expect(page).to have_current_path users_sign_up_welcome_path
          expect(page).to have_content('Welcome to GitLab, mockuser!')
        end

        context 'when terms are enforced' do
          before do
            enforce_terms
          end

          it 'auto accepts terms and redirects to the initial welcome path' do
            register_via(provider, uid, email, additional_info: additional_info)

            expect(page).to have_current_path users_sign_up_welcome_path
            expect(page).to have_content('Welcome to GitLab, mockuser!')
          end
        end

        context 'when provider does not send a verified email address' do
          let(:email) { 'temp-email-for-oauth@email.com' }

          it 'redirects to the profile path' do
            register_via(provider, uid, email, additional_info: additional_info)

            expect(page).to have_current_path profile_path
            expect(page).to have_content('Please complete your profile with email address')
          end
        end
      end
    end
  end
end

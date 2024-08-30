# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'OAuth Registration', :js, :allow_forgery_protection, :with_current_organization, feature_category: :system_access do
  include LoginHelpers
  include TermsHelper
  using RSpec::Parameterized::TableSyntax

  let(:uid) { 'my-uid' }
  let(:email) { 'user@example.com' }

  around do |example|
    with_omniauth_full_host { example.run }
  end

  where(:provider, :additional_info) do
    :github         | {}
    :bitbucket      | {}
    :gitlab         | {}
    :google_oauth2  | {}
    :auth0          | {}
    :salesforce     | { extra: { email_verified: true } }
    :alicloud       | {}
  end

  with_them do
    before do
      stub_omniauth_provider(provider)
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

      it 'redirects to the dashboard projects path' do
        register_via(provider, uid, email, additional_info: additional_info)

        expect(page).to have_current_path dashboard_projects_path
        expect(page).to have_content('Welcome to GitLab')
      end

      context 'when terms are enforced' do
        before do
          enforce_terms
        end

        it 'auto accepts terms and redirects to the dashboard projects path' do
          register_via(provider, uid, email, additional_info: additional_info)

          expect(page).to have_current_path dashboard_projects_path
          expect(page).to have_content('Welcome to GitLab')
        end
      end

      context 'when provider does not send a verified email address' do
        let(:email) { 'temp-email-for-oauth@email.com' }

        it 'redirects to the profile path' do
          register_via(provider, uid, email, additional_info: additional_info)

          expect(page).to have_current_path user_settings_profile_path
          expect(page).to have_content('Please complete your profile with email address')
        end
      end

      context 'when registering via an invitation email' do
        let_it_be(:owner) { create(:user) }
        let_it_be(:group) { create(:group, name: 'Owned') }
        let_it_be(:project) { create(:project, :repository, namespace: group) }

        let(:invite_email) { generate(:email) }
        let(:extra_params) { { invite_type: ::Members::InviteMailer::INITIAL_INVITE } }
        let(:group_invite) do
          create(
            :group_member, :invited,
            group: group,
            invite_email: invite_email,
            created_by: owner
          )
        end

        before do
          project.add_maintainer(owner)
          group.add_owner(owner)
          group_invite.generate_invite_token!

          mock_auth_hash(provider, uid, invite_email, additional_info: additional_info)
        end

        it 'redirects to the group page with all the projects/groups invitations accepted' do
          visit invite_path(group_invite.raw_invite_token, extra_params)
          click_link_or_button Gitlab::Auth::OAuth::Provider.label_for(provider)

          expect(page)
            .to have_content('You have been granted access to the Owned group with the following role: Owner.')
          expect(page).to have_current_path(group_path(group), ignore_query: true)
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Projects > Show > Access', feature_category: :groups_and_projects do
  describe 'No password alert', :with_current_organization do
    let_it_be(:message_password_auth_enabled) { 'Your account is authenticated with SSO or SAML. To push and pull over HTTP with Git using this account, you must set a password or set up a personal access token to use instead of a password.' }
    let_it_be(:message_password_auth_disabled) { 'Your account is authenticated with SSO or SAML. To push and pull over HTTP with Git using this account, you must set up a personal access token to use instead of a password.' }

    let(:project) { create(:project, :repository, namespace: user.namespace) }

    context 'with internal auth enabled' do
      before do
        sign_in(user)
        visit project_path(project)
      end

      context 'when user has a password' do
        let(:user) { create(:user) }

        it 'shows no alert' do
          expect(page).not_to have_content message_password_auth_enabled
        end
      end

      context 'when user has password automatically set' do
        let(:user) { create(:user, password_automatically_set: true) }

        it 'shows a password alert' do
          expect(page).to have_content message_password_auth_enabled
        end
      end
    end

    context 'with internal auth disabled' do
      let(:user) { create(:omniauth_user, extern_uid: 'my-uid', provider: 'saml') }

      before do
        stub_application_setting(password_authentication_enabled_for_git?: false)
        stub_omniauth_saml_config(enabled: true, auto_link_saml_user: true, allow_single_sign_on: ['saml'], providers: [mock_saml_config])
      end

      context 'when user has no personal access tokens' do
        it 'has a personal access token alert' do
          gitlab_sign_in_via('saml', user, 'my-uid')
          visit project_path(project)

          expect(page).to have_content message_password_auth_disabled
        end
      end

      context 'when user has a personal access token' do
        it 'shows no alert' do
          create(:personal_access_token, user: user)
          gitlab_sign_in_via('saml', user, 'my-uid')
          visit project_path(project)

          expect(page).not_to have_content message_password_auth_disabled
        end
      end
    end

    context 'when user is ldap user' do
      let(:user) { create(:omniauth_user, password_automatically_set: true) }

      before do
        sign_in(user)
        visit project_path(project)
      end

      it 'shows no alert' do
        expect(page).not_to have_content "You won't be able to pull or push repositories via HTTP until you"
      end
    end
  end

  describe 'Redirects' do
    let(:user) { create :user }
    let(:public_project) { create :project, :public }
    let(:private_project) { create :project, :private }

    before do
      allow(Gitlab.config.gitlab).to receive(:host).and_return('www.example.com')
    end

    it 'shows public project page', :js do
      visit project_path(public_project)

      within_testid 'breadcrumb-links' do
        expect(find('li:last-of-type')).to have_content(public_project.name)
      end
    end

    it 'redirects to sign in page when project is private' do
      visit project_path(private_project)

      expect(page).to have_current_path(new_user_session_path, ignore_query: true)
    end

    it 'redirects to sign in page when project does not exist' do
      visit project_path(build(:project, :public))

      expect(page).to have_current_path(new_user_session_path, ignore_query: true)
    end

    it 'redirects to public project page after signing in', :js do
      visit project_path(public_project)

      first(:link, 'Sign in').click

      fill_in 'user_login',    with: user.email
      fill_in 'user_password', with: user.password
      click_button 'Sign in'

      expect(page).to have_current_path("/#{public_project.full_path}", ignore_query: true)
    end

    it 'redirects to private project page after sign in', :js do
      visit project_path(private_project)

      owner = private_project.first_owner
      fill_in 'user_login',    with: owner.email
      fill_in 'user_password', with: owner.password
      click_button 'Sign in'

      expect(page).to have_content('No repository')
      expect(page).to have_current_path("/#{private_project.full_path}", ignore_query: true)
    end

    context 'when signed in' do
      before do
        sign_in(user)
      end

      it 'returns 404 status when project does not exist' do
        visit project_path(build(:project, :public))

        expect(status_code).to eq(404)
      end

      it 'returns 404 when project is private' do
        visit project_path(private_project)

        expect(status_code).to eq(404)
      end
    end
  end
end

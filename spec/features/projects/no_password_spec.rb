require 'spec_helper'

feature 'No Password Alert' do
  let(:project) { create(:project, :repository, namespace: user.namespace) }

  context 'with internal auth enabled' do
    before do
      sign_in(user)
      visit project_path(project)
    end

    context 'when user has a password' do
      let(:user) { create(:user) }

      it 'shows no alert' do
        expect(page).not_to have_content "You won't be able to pull or push project code via HTTP until you set a password on your account"
      end
    end

    context 'when user has password automatically set' do
      let(:user) { create(:user, password_automatically_set: true) }

      it 'shows a password alert' do
        expect(page).to have_content "You won't be able to pull or push project code via HTTP until you set a password on your account"
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

        expect(page).to have_content "You won't be able to pull or push project code via HTTP until you create a personal access token on your account"
      end
    end

    context 'when user has a personal access token' do
      it 'shows no alert' do
        create(:personal_access_token, user: user)
        gitlab_sign_in_via('saml', user, 'my-uid')
        visit project_path(project)

        expect(page).not_to have_content "You won't be able to pull or push project code via HTTP until you create a personal access token on your account"
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
      expect(page).not_to have_content "You won't be able to pull or push project code via HTTP until you"
    end
  end
end

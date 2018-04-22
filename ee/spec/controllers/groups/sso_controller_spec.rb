require 'spec_helper'

describe Groups::SsoController do
  include CookieHelper

  let(:user) { create(:user) }
  let(:group) { create(:group, :private, name: 'our-group') }
  let(:enable_group_saml_cookie) { 'true' }

  before do
    request.cookies['enable_group_saml'] = enable_group_saml_cookie
    stub_licensed_features(group_saml: true)
    allow(Devise).to receive(:omniauth_providers).and_return(%i(group_saml))
    sign_in(user)
  end

  context 'SAML configured' do
    let!(:saml_provider) { create(:saml_provider, group: group) }

    it 'has status 200' do
      get :saml, group_id: group

      expect(response).to have_gitlab_http_status(200)
    end

    it 'passes group name to the view' do
      get :saml, group_id: group

      expect(assigns[:group_name]).to eq 'our-group'
    end

    context 'when beta cookie not set' do
      let(:enable_group_saml_cookie) { 'false' }

      it 'renders 404' do
        get :saml, group_id: group

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when user is not signed in' do
      it 'acts as route not found' do
        sign_out(user)

        get :saml, group_id: group

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context 'when group has moved' do
      let(:redirect_route) { group.redirect_routes.create(path: 'old-path') }

      it 'redirects to new location' do
        get :saml, group_id: redirect_route.path

        expect(response).to redirect_to(sso_group_saml_providers_path(group))
      end
    end
  end

  context 'saml_provider is unconfigured for the group' do
    context 'when user cannot configure Group SAML' do
      it 'renders 404' do
        get :saml, group_id: group

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when user can admin group_saml' do
      before do
        group.add_owner(user)
      end

      it 'redirects to the Group SAML config page' do
        get :saml, group_id: group

        expect(response).to redirect_to(group_saml_providers_path)
      end

      it 'sets a flash message explaining that setup is required' do
        get :saml, group_id: group

        expect(flash[:notice]).to match /not been configured/
      end
    end
  end

  context 'group does not exist' do
    it 'renders 404' do
      get :saml, group_id: 'not-a-group'

      expect(response).to have_gitlab_http_status(404)
    end

    context 'when user is not signed in' do
      it 'acts as route not found' do
        sign_out(user)

        get :saml, group_id: 'not-a-group'

        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end

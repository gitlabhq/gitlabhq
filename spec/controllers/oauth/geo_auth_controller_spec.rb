require 'spec_helper'

describe Oauth::GeoAuthController do
  let(:user) { create(:user) }
  let(:oauth_app) { create(:doorkeeper_application) }
  let(:access_token) { create(:doorkeeper_access_token, resource_owner_id: user.id).token }
  let(:auth_state) { Gitlab::Geo::OauthSession.new(access_token: access_token, return_to: projects_url).generate_oauth_state }
  let(:primary_node_url) { 'http://localhost:3001/' }

  before do
    allow_any_instance_of(Gitlab::Geo::OauthSession).to receive(:oauth_app) { oauth_app }
    allow_any_instance_of(Gitlab::Geo::OauthSession).to receive(:primary_node_url) { primary_node_url }
  end

  describe 'GET auth' do
    let(:primary_node_oauth_endpoint) { Gitlab::Geo::OauthSession.new.authorize_url(redirect_uri: oauth_geo_callback_url, state: auth_state) }

    it 'redirects to root_url when state is invalid' do
      allow_any_instance_of(Gitlab::Geo::OauthSession).to receive(:is_oauth_state_valid?) { false }
      get :auth, state: auth_state

      expect(response).to redirect_to(root_url)
    end

    it "redirects to primary node's oauth endpoint" do
      get :auth, state: auth_state

      expect(response).to redirect_to(primary_node_oauth_endpoint)
    end
  end

  describe 'GET callback' do
    let(:callback_state) { Gitlab::Geo::OauthSession.new(access_token: access_token, return_to: projects_url).generate_oauth_state }
    let(:primary_node_oauth_endpoint) { Gitlab::Geo::OauthSession.new.authorize_url(redirect_uri: oauth_geo_callback_url, state: callback_state) }

    context 'redirection' do
      before do
        allow_any_instance_of(Gitlab::Geo::OauthSession).to receive(:get_token) { 'token' }
        allow_any_instance_of(Gitlab::Geo::OauthSession).to receive(:authenticate_with_gitlab) { user.attributes }
      end

      it 'redirects to login screen if state is invalid' do
        allow_any_instance_of(Gitlab::Geo::OauthSession).to receive(:is_oauth_state_valid?) { false }
        get :callback, state: callback_state

        expect(response).to redirect_to(new_user_session_path)
      end

      it 'redirects to redirect_url if state is valid' do
        get :callback, state: callback_state

        expect(response).to redirect_to(projects_url)
      end
    end

    context 'invalid credentials' do
      let(:fake_response) { double('Faraday::Response', headers: {}, body: '', status: 403) }
      let(:oauth_error) { OAuth2::Error.new(OAuth2::Response.new(fake_response)) }

      before do
        expect_any_instance_of(Gitlab::Geo::OauthSession).to receive(:get_token) { access_token }
        expect_any_instance_of(Gitlab::Geo::OauthSession).to receive(:authenticate_with_gitlab).and_raise(oauth_error)
      end

      it 'handles invalid credentials error' do
        get :callback, state: callback_state

        expect(response).to redirect_to(primary_node_oauth_endpoint)
      end
    end

    context 'inexistent local user' do
      render_views

      before do
        expect_any_instance_of(Gitlab::Geo::OauthSession).to receive(:get_token) { 'token' }
        expect_any_instance_of(Gitlab::Geo::OauthSession).to receive(:authenticate_with_gitlab) { User.new(id: 999999) }
      end

      it 'handles inexistent local user error' do
        get :callback, state: callback_state

        expect(response.code).to eq '200'
        expect(response.body).to include('Your account may have been deleted')
      end
    end
  end

  describe 'GET logout' do
    let(:logout_state) { Gitlab::Geo::OauthSession.new(access_token: access_token).generate_logout_state }

    context 'access_token error' do
      render_views

      before do
        allow(controller).to receive(:current_user) { user }
      end

      it 'logs out when correct access_token is informed' do
        get :logout, state: logout_state

        expect(response).to redirect_to root_url
      end

      it 'handles access token problems' do
        allow_any_instance_of(Oauth2::LogoutTokenValidationService).to receive(:execute) { { status: :error, message: :expired } }
        get :logout, state: logout_state

        expect(response.body).to include("There is a problem with the OAuth access_token: expired")
      end
    end
  end
end

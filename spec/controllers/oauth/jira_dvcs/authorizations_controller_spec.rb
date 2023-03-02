# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Oauth::JiraDvcs::AuthorizationsController, feature_category: :integrations do
  let_it_be(:application) { create(:oauth_application, redirect_uri: 'https://example.com/callback') }

  describe 'GET new' do
    it 'redirects to OAuth authorization with correct params' do
      get :new, params: { client_id: application.uid, scope: 'foo', redirect_uri: 'https://example.com/callback' }

      expect(response).to redirect_to(oauth_authorization_url(
        client_id: application.uid,
        response_type: 'code',
        scope: 'foo',
        redirect_uri: oauth_jira_dvcs_callback_url))
    end

    it 'replaces the GitHub "repo" scope with "api"' do
      get :new, params: { client_id: application.uid, scope: 'repo', redirect_uri: 'https://example.com/callback' }

      expect(response).to redirect_to(oauth_authorization_url(
        client_id: application.uid,
        response_type: 'code',
        scope: 'api',
        redirect_uri: oauth_jira_dvcs_callback_url))
    end

    it 'returns 404 with an invalid client' do
      get :new, params: { client_id: 'client-123', scope: 'foo', redirect_uri: 'https://example.com/callback' }

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'returns 403 with an incorrect redirect_uri' do
      get :new, params: { client_id: application.uid, scope: 'foo', redirect_uri: 'http://unsafe-website.com/callback' }

      expect(response).to have_gitlab_http_status(:forbidden)
    end
  end

  describe 'GET callback' do
    it 'redirects to redirect_uri on session with code param' do
      session['redirect_uri'] = 'http://example.com'

      get :callback, params: { code: 'hash-123' }

      expect(response).to redirect_to('http://example.com?code=hash-123')
    end

    it 'redirects to redirect_uri on session with code param preserving existing query' do
      session['redirect_uri'] = 'http://example.com?foo=bar'

      get :callback, params: { code: 'hash-123' }

      expect(response).to redirect_to('http://example.com?foo=bar&code=hash-123')
    end
  end

  describe 'POST access_token' do
    it 'returns oauth params in a format Jira expects' do
      expect_any_instance_of(Doorkeeper::Request::AuthorizationCode).to receive(:authorize) do
        double(status: :ok, body: { 'access_token' => 'fake-123', 'scope' => 'foo', 'token_type' => 'bar' })
      end

      post :access_token, params: { code: 'code-123', client_id: application.uid, client_secret: 'secret-123' }

      expect(response.body).to eq('access_token=fake-123&scope=foo&token_type=bar')
    end
  end
end

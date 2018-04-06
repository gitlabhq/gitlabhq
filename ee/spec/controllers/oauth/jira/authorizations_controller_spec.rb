require 'spec_helper'

describe Oauth::Jira::AuthorizationsController do
  describe 'GET new' do
    it 'redirects to OAuth authorization with correct params' do
      get :new, client_id: 'client-123', redirect_uri: 'http://example.com/'

      expect(response).to redirect_to(oauth_authorization_url(client_id: 'client-123',
                                                              response_type: 'code',
                                                              redirect_uri: oauth_jira_callback_url))
    end
  end

  describe 'GET callback' do
    it 'redirects to redirect_uri on session with code param' do
      session['redirect_uri'] = 'http://example.com'

      get :callback, code: 'hash-123'

      expect(response).to redirect_to('http://example.com?code=hash-123')
    end

    it 'redirects to redirect_uri on session with code param preserving existing query' do
      session['redirect_uri'] = 'http://example.com?foo=bar'

      get :callback, code: 'hash-123'

      expect(response).to redirect_to('http://example.com?foo=bar&code=hash-123')
    end
  end

  describe 'POST access_token' do
    it 'send post call to oauth_token_url with correct params' do
      expected_auth_params = { 'code' => 'code-123',
                               'client_id' => 'client-123',
                               'client_secret' => 'secret-123',
                               'grant_type' => 'authorization_code',
                               'redirect_uri' => 'http://test.host/-/jira/login/oauth/callback' }

      expect(Gitlab::HTTP).to receive(:post).with(oauth_token_url, allow_local_requests: true, body: expected_auth_params) do
        { 'access_token' => 'fake-123', 'scope' => 'foo', 'token_type' => 'bar' }
      end

      post :access_token, code: 'code-123', client_id: 'client-123', client_secret: 'secret-123'

      expect(response.body).to eq('access_token=fake-123&scope=foo&token_type=bar')
    end
  end
end

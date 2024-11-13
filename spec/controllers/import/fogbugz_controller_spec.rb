# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::FogbugzController, feature_category: :importers do
  include ImportSpecHelper

  let(:user) { create(:user) }
  let(:token) { FFaker::Lorem.characters(8) }
  let(:uri) { 'https://example.com' }
  let(:namespace_id) { 5 }

  before do
    stub_application_setting(import_sources: ['fogbugz'])

    sign_in(user)
  end

  describe 'POST #callback' do
    let(:xml_response) { %(<?xml version=\"1.0\" encoding=\"UTF-8\"?><response><token><![CDATA[#{token}]]></token></response>) }

    before do
      stub_request(:post, "https://example.com/api.asp").to_return(status: 200, body: xml_response, headers: {})
    end

    it 'attempts to contact Fogbugz server' do
      post :callback, params: { uri: uri, email: 'test@example.com', password: 'mypassword' }

      expect(session[:fogbugz_token]).to eq(token)
      expect(session[:fogbugz_uri]).to eq(uri)
      expect(response).to redirect_to(new_user_map_import_fogbugz_path)
    end

    it 'preserves namespace_id query param on success' do
      post :callback, params: { uri: uri, email: 'test@example.com', password: 'mypassword', namespace_id: namespace_id }

      expect(response).to redirect_to(new_user_map_import_fogbugz_path(namespace_id: namespace_id))
    end

    it 'redirects to new page maintaining namespace_id when client raises standard error' do
      namespace_id = 5
      allow(::Gitlab::FogbugzImport::Client).to receive(:new).and_raise(StandardError)

      post :callback, params: { uri: uri, email: 'test@example.com', password: 'mypassword', namespace_id: namespace_id }

      expect(response).to redirect_to(new_import_fogbugz_url(namespace_id: namespace_id))
    end

    context 'when client raises authentication exception' do
      before do
        allow(::Gitlab::FogbugzImport::Client).to receive(:new).and_raise(::Fogbugz::AuthenticationException)
      end

      it 'redirects to new page form' do
        post :callback, params: { uri: uri, email: 'test@example.com', password: 'mypassword' }

        expect(response).to redirect_to(new_import_fogbugz_url)
      end
    end

    context 'verify url' do
      shared_examples 'denies local request' do |reason|
        it 'does not allow requests' do
          post :callback, params: { uri: uri, email: 'test@example.com', password: 'mypassword' }

          expect(response).to redirect_to(new_import_fogbugz_url)
          expect(flash[:alert]).to eq("Specified URL cannot be used: \"#{reason}\"")
        end
      end

      context 'when host is localhost' do
        let(:uri) { 'https://localhost:3000' }

        include_examples 'denies local request', 'Requests to localhost are not allowed'
      end

      context 'when host is on local network' do
        let(:uri) { 'http://192.168.0.1/' }

        include_examples 'denies local request', 'Requests to the local network are not allowed'
      end

      context 'when host is ftp protocol' do
        let(:uri) { 'ftp://testing' }

        include_examples 'denies local request', 'Only allowed schemes are http, https'
      end
    end

    it_behaves_like 'rate limited endpoint', rate_limit_key: :fogbugz_import, with_redirect: true do
      let(:current_user) { user }

      def request
        post :callback, params: { uri: uri, email: 'test@example.com', password: 'mypassword' }
      end
    end
  end

  describe 'POST #create_user_map' do
    let(:user_map) do
      {
        "2" => {
          "name" => "Test User",
          "email" => "testuser@example.com",
          "gitlab_user" => "3"
        }
      }
    end

    it 'stores the user map in the session' do
      client = double(user_map: {})
      expect(controller).to receive(:client).and_return(client)

      post :create_user_map, params: { users: user_map }

      expect(session[:fogbugz_user_map]).to eq(user_map)
      expect(response).to redirect_to(status_import_fogbugz_path)
    end

    it 'preserves namespace_id query param' do
      client = double(user_map: {})
      expect(controller).to receive(:client).and_return(client)

      post :create_user_map, params: { users: user_map, namespace_id: namespace_id }

      expect(session[:fogbugz_user_map]).to eq(user_map)
      expect(response).to redirect_to(status_import_fogbugz_path(namespace_id: namespace_id))
    end
  end

  describe 'GET status' do
    let(:repo) do
      instance_double(Gitlab::FogbugzImport::Repository, id: 'demo', name: 'vim', safe_name: 'vim', path: 'vim')
    end

    it 'redirects to new page form when client is invalid' do
      stub_client(valid?: false)

      get :status

      expect(response).to redirect_to(new_import_fogbugz_path)
    end

    it_behaves_like 'import controller status' do
      before do
        stub_client(valid?: true)
      end

      let(:repo_id) { repo.id }
      let(:import_source) { repo.name }
      let(:provider_name) { 'fogbugz' }
      let(:client_repos_field) { :repos }
    end
  end

  describe 'POST create', :with_current_organization do
    let(:repo_id) { 'FOGBUGZ_REPO_ID' }
    let(:project) { create(:project) }
    let(:client) { instance_double(Gitlab::FogbugzImport::Client, user_map: {}) }

    before do
      allow(controller).to receive(:client).and_return(client)
    end

    it 'returns the new project' do
      expect(Import::FogbugzService).to receive(:new).with(client, user, hash_including(organization_id: current_organization.id)).and_return(
        instance_double(Import::FogbugzService, execute: ServiceResponse.success)
      )

      post :create, format: :json

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'returns an error when service reports an error' do
      message = 'Error message'
      status = :unprocessable_entity

      expect(Import::FogbugzService).to receive(:new).and_return(
        instance_double(Import::FogbugzService, execute: ServiceResponse.error(message: message, http_status: status))
      )

      post :create, format: :json

      expect(response).to have_gitlab_http_status(status)
      expect(json_response).to eq({ 'errors' => message })
    end

    it_behaves_like 'project import rate limiter'
  end
end

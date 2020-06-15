# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::FogbugzController do
  include ImportSpecHelper

  let(:user) { create(:user) }

  before do
    sign_in(user)
  end

  describe 'POST #callback' do
    let(:token) { FFaker::Lorem.characters(8) }
    let(:uri) { 'https://example.com' }
    let(:xml_response) { %Q(<?xml version=\"1.0\" encoding=\"UTF-8\"?><response><token><![CDATA[#{token}]]></token></response>) }

    it 'attempts to contact Fogbugz server' do
      stub_request(:post, "https://example.com/api.asp").to_return(status: 200, body: xml_response, headers: {})

      post :callback, params: { uri: uri, email: 'test@example.com', password: 'mypassword' }

      expect(session[:fogbugz_token]).to eq(token)
      expect(session[:fogbugz_uri]).to eq(uri)
      expect(response).to redirect_to(new_user_map_import_fogbugz_path)
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
  end

  describe 'GET status' do
    before do
      @repo = OpenStruct.new(id: 'demo', name: 'vim')
      stub_client(valid?: true)
      stub_feature_flags(new_import_ui: false)
    end

    it_behaves_like 'import controller with new_import_ui feature flag' do
      let(:repo) { @repo }
      let(:repo_id) { @repo.id }
      let(:import_source) { @repo.name }
      let(:provider_name) { 'fogbugz' }
      let(:client_repos_field) { :repos }
    end

    it 'assigns variables' do
      @project = create(:project, import_type: 'fogbugz', creator_id: user.id)
      stub_client(repos: [@repo])

      get :status

      expect(assigns(:already_added_projects)).to eq([@project])
      expect(assigns(:repos)).to eq([@repo])
    end

    it 'does not show already added project' do
      @project = create(:project, import_type: 'fogbugz', creator_id: user.id, import_source: 'vim')
      stub_client(repos: [@repo])

      get :status

      expect(assigns(:already_added_projects)).to eq([@project])
      expect(assigns(:repos)).to eq([])
    end
  end

  describe 'POST create' do
    it_behaves_like 'project import rate limiter'
  end
end

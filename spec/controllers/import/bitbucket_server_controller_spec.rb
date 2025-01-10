# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::BitbucketServerController, feature_category: :importers do
  let(:user) { create(:user) }
  let(:project_key) { 'test-project' }
  let(:repo_slug) { 'some-repo' }
  let(:repo_id) { "#{project_key}/#{repo_slug}" }
  let(:client) { instance_double(BitbucketServer::Client) }
  let(:timeout_strategy) { "pessimistic" }

  def assign_session_tokens
    session[:bitbucket_server_url] = 'http://localhost:7990'
    session[:bitbucket_server_username] = 'bitbucket'
    session[:bitbucket_server_personal_access_token] = 'some-token'
  end

  before do
    sign_in(user)
    stub_application_setting(import_sources: ['bitbucket_server'])
  end

  describe 'GET new' do
    render_views

    it 'shows the input form' do
      get :new

      expect(response.body).to have_text('Bitbucket Server URL')
    end
  end

  describe 'POST create', :with_current_organization do
    let(:project_name) { "my-project_123" }
    let(:params) { { repo_id: repo_id } }

    before do
      allow(controller).to receive(:client).and_return(client)
      repo = double(name: project_name)
      allow(client).to receive(:repo).with(project_key, repo_slug).and_return(repo)
      assign_session_tokens
    end

    let_it_be(:project) { create(:project) }

    it 'returns the new project' do
      allow(Gitlab::BitbucketServerImport::ProjectCreator)
        .to receive(:new).with(project_key, repo_slug, anything, project_name, user.namespace, user, anything, timeout_strategy)
        .and_return(double(execute: project))
      expect(Import::BitbucketServerService).to receive(:new).with(client, user, hash_including(params.merge(organization_id: current_organization.id))).and_call_original

      post :create, params: params, format: :json

      expect(response).to have_gitlab_http_status(:ok)
    end

    context 'with project key with tildes' do
      let(:project_key) { '~someuser_123' }

      it 'successfully creates a project' do
        allow(Gitlab::BitbucketServerImport::ProjectCreator)
          .to receive(:new).with(project_key, repo_slug, anything, project_name, user.namespace, user, anything, timeout_strategy)
          .and_return(double(execute: project))

        post :create, params: params, format: :json

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when bitbucket server importer is not enabled' do
      before do
        stub_application_setting(import_sources: [])
      end

      it 'returns 404' do
        post :create, params: params, format: :json

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    it 'returns an error when an invalid project key is used' do
      post :create, params: { repo_id: 'some&project/repo' }

      expect(response).to have_gitlab_http_status(:unprocessable_entity)
    end

    it 'returns an error when an invalid repository slug is used' do
      post :create, params: { repo_id: 'some-project/try*this' }

      expect(response).to have_gitlab_http_status(:unprocessable_entity)
    end

    it 'returns an error when the project cannot be found' do
      allow(client).to receive(:repo).with(project_key, repo_slug).and_return(nil)

      post :create, params: params, format: :json

      expect(response).to have_gitlab_http_status(:unprocessable_entity)
    end

    it 'returns an error when the project cannot be saved' do
      allow(Gitlab::BitbucketServerImport::ProjectCreator)
        .to receive(:new).with(project_key, repo_slug, anything, project_name, user.namespace, user, anything, timeout_strategy)
        .and_return(double(execute: build(:project)))

      post :create, params: params, format: :json

      expect(response).to have_gitlab_http_status(:unprocessable_entity)
    end

    it "returns an error when the server can't be contacted" do
      allow(client).to receive(:repo).with(project_key, repo_slug).and_raise(::BitbucketServer::Connection::ConnectionError)

      post :create, params: params, format: :json

      expect(response).to have_gitlab_http_status(:unprocessable_entity)
    end

    it_behaves_like 'project import rate limiter'
  end

  describe 'POST configure' do
    let(:token) { 'token' }
    let(:username) { 'bitbucket-user' }
    let(:url) { 'http://localhost:7990/bitbucket' }

    it 'clears out existing session' do
      post :configure

      expect(session[:bitbucket_server_url]).to be_nil
      expect(session[:bitbucket_server_username]).to be_nil
      expect(session[:bitbucket_server_personal_access_token]).to be_nil

      expect(response).to have_gitlab_http_status(:found)
      expect(response).to redirect_to(status_import_bitbucket_server_path)
    end

    it 'sets the session variables' do
      allow(controller).to receive(:allow_local_requests?).and_return(true)

      post :configure, params: { personal_access_token: token, bitbucket_server_username: username, bitbucket_server_url: url }

      expect(session[:bitbucket_server_url]).to eq(url)
      expect(session[:bitbucket_server_username]).to eq(username)
      expect(session[:bitbucket_server_personal_access_token]).to eq(token)
      expect(response).to have_gitlab_http_status(:found)
      expect(response).to redirect_to(status_import_bitbucket_server_path)
    end

    it 'passes namespace_id to status page if provided' do
      namespace_id = 5
      allow(controller).to receive(:allow_local_requests?).and_return(true)

      post :configure, params: { personal_access_token: token, bitbucket_server_username: username, bitbucket_server_url: url, namespace_id: namespace_id }

      expect(response).to redirect_to(status_import_bitbucket_server_path(namespace_id: namespace_id))
    end
  end

  describe 'GET status' do
    render_views

    before do
      allow(controller).to receive(:client).and_return(client)

      @repo = double(slug: 'vim', project_key: 'asd', full_name: 'asd/vim', "valid?" => true, project_name: 'asd', browse_url: 'http://test', name: 'vim')
      @invalid_repo = double(slug: 'invalid', project_key: 'foobar', full_name: 'asd/foobar', "valid?" => false, browse_url: 'http://bad-repo', name: 'invalid')
      @created_repo = double(slug: 'created', project_key: 'existing', full_name: 'group/created', "valid?" => true, browse_url: 'http://existing')
      assign_session_tokens
    end

    it 'returns invalid repos' do
      allow(client).to receive(:repos).with(filter: nil, limit: 25, page_offset: 0).and_return([@repo, @invalid_repo])

      get :status, format: :json

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['incompatible_repos'].length).to eq(1)
      expect(json_response.dig("incompatible_repos", 0, "id")).to eq("#{@invalid_repo.project_key}/#{@invalid_repo.slug}")
      expect(json_response['provider_repos'].length).to eq(1)
      expect(json_response.dig("provider_repos", 0, "id")).to eq(@repo.full_name)
    end

    it 'redirects to connection form if session is missing auth data' do
      session[:bitbucket_server_url] = nil

      get :status, format: :html

      expect(response).to redirect_to(new_import_bitbucket_server_path)
    end

    it_behaves_like 'import controller status' do
      let(:repo) { @repo }
      let(:repo_id) { "#{@repo.project_key}/#{@repo.slug}" }
      let(:import_source) { @repo.browse_url }
      let(:provider_name) { 'bitbucket_server' }
      let(:client_repos_field) { :repos }
    end

    context 'when filtering' do
      let(:filter) { 'test' }

      it 'passes filter param to bitbucket client' do
        expect(client).to receive(:repos).with(filter: filter, limit: 25, page_offset: 0).and_return([@repo])

        get :status, params: { filter: filter }, as: :json
      end
    end
  end
end

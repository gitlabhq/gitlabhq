# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::BitbucketServerController do
  let(:user) { create(:user) }
  let(:project_key) { 'test-project' }
  let(:repo_slug) { 'some-repo' }
  let(:client) { instance_double(BitbucketServer::Client) }

  def assign_session_tokens
    session[:bitbucket_server_url] = 'http://localhost:7990'
    session[:bitbucket_server_username] = 'bitbucket'
    session[:bitbucket_server_personal_access_token] = 'some-token'
  end

  before do
    sign_in(user)
    allow(controller).to receive(:bitbucket_server_import_enabled?).and_return(true)
  end

  describe 'GET new' do
    render_views

    it 'shows the input form' do
      get :new

      expect(response.body).to have_text('Bitbucket Server URL')
    end
  end

  describe 'POST create' do
    let(:project_name) { "my-project_123" }

    before do
      allow(controller).to receive(:client).and_return(client)
      repo = double(name: project_name)
      allow(client).to receive(:repo).with(project_key, repo_slug).and_return(repo)
      assign_session_tokens
    end

    let_it_be(:project) { create(:project) }

    it 'returns the new project' do
      allow(Gitlab::BitbucketServerImport::ProjectCreator)
        .to receive(:new).with(project_key, repo_slug, anything, project_name, user.namespace, user, anything)
        .and_return(double(execute: project))

      post :create, params: { project: project_key, repository: repo_slug }, format: :json

      expect(response).to have_gitlab_http_status(:ok)
    end

    context 'with project key with tildes' do
      let(:project_key) { '~someuser_123' }

      it 'successfully creates a project' do
        allow(Gitlab::BitbucketServerImport::ProjectCreator)
          .to receive(:new).with(project_key, repo_slug, anything, project_name, user.namespace, user, anything)
          .and_return(double(execute: project))

        post :create, params: { project: project_key, repository: repo_slug, format: :json }

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    it 'returns an error when an invalid project key is used' do
      post :create, params: { project: 'some&project' }

      expect(response).to have_gitlab_http_status(:unprocessable_entity)
    end

    it 'returns an error when an invalid repository slug is used' do
      post :create, params: { project: 'some-project', repository: 'try*this' }

      expect(response).to have_gitlab_http_status(:unprocessable_entity)
    end

    it 'returns an error when the project cannot be found' do
      allow(client).to receive(:repo).with(project_key, repo_slug).and_return(nil)

      post :create, params: { project: project_key, repository: repo_slug }, format: :json

      expect(response).to have_gitlab_http_status(:unprocessable_entity)
    end

    it 'returns an error when the project cannot be saved' do
      allow(Gitlab::BitbucketServerImport::ProjectCreator)
        .to receive(:new).with(project_key, repo_slug, anything, project_name, user.namespace, user, anything)
        .and_return(double(execute: build(:project)))

      post :create, params: { project: project_key, repository: repo_slug }, format: :json

      expect(response).to have_gitlab_http_status(:unprocessable_entity)
    end

    it "returns an error when the server can't be contacted" do
      expect(client).to receive(:repo).with(project_key, repo_slug).and_raise(::BitbucketServer::Connection::ConnectionError)

      post :create, params: { project: project_key, repository: repo_slug }, format: :json

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
      post :configure, params: { personal_access_token: token, bitbucket_username: username, bitbucket_server_url: url }

      expect(session[:bitbucket_server_url]).to eq(url)
      expect(session[:bitbucket_server_username]).to eq(username)
      expect(session[:bitbucket_server_personal_access_token]).to eq(token)
      expect(response).to have_gitlab_http_status(:found)
      expect(response).to redirect_to(status_import_bitbucket_server_path)
    end
  end

  describe 'GET status' do
    render_views

    let(:repos) { instance_double(BitbucketServer::Collection) }

    before do
      allow(controller).to receive(:client).and_return(client)

      @repo = double(slug: 'vim', project_key: 'asd', full_name: 'asd/vim', "valid?" => true, project_name: 'asd', browse_url: 'http://test', name: 'vim')
      @invalid_repo = double(slug: 'invalid', project_key: 'foobar', full_name: 'asd/foobar', "valid?" => false, browse_url: 'http://bad-repo', name: 'invalid')
      @created_repo = double(slug: 'created', project_key: 'existing', full_name: 'group/created', "valid?" => true, browse_url: 'http://existing')
      assign_session_tokens
      stub_feature_flags(new_import_ui: false)
    end

    context 'with new_import_ui feature flag enabled' do
      before do
        stub_feature_flags(new_import_ui: true)
      end

      it 'returns invalid repos' do
        allow(client).to receive(:repos).with(filter: nil, limit: 25, page_offset: 0).and_return([@repo, @invalid_repo])

        get :status, format: :json

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['incompatible_repos'].length).to eq(1)
        expect(json_response.dig("incompatible_repos", 0, "id")).to eq(@invalid_repo.full_name)
        expect(json_response['provider_repos'].length).to eq(1)
        expect(json_response.dig("provider_repos", 0, "id")).to eq(@repo.full_name)
      end
    end

    it_behaves_like 'import controller with new_import_ui feature flag' do
      let(:repo) { @repo }
      let(:repo_id) { @repo.full_name }
      let(:import_source) { @repo.browse_url }
      let(:provider_name) { 'bitbucket_server' }
      let(:client_repos_field) { :repos }
    end

    it 'assigns repository categories' do
      created_project = create(:project, :import_finished, import_type: 'bitbucket_server', creator_id: user.id, import_source: @created_repo.browse_url)

      expect(repos).to receive(:partition).and_return([[@repo, @created_repo], [@invalid_repo]])
      expect(repos).to receive(:current_page).and_return(1)
      expect(repos).to receive(:next_page).and_return(2)
      expect(repos).to receive(:prev_page).and_return(nil)
      expect(client).to receive(:repos).and_return(repos)

      get :status

      expect(assigns(:already_added_projects)).to eq([created_project])
      expect(assigns(:repos)).to eq([@repo])
      expect(assigns(:incompatible_repos)).to eq([@invalid_repo])
    end

    context 'when filtering' do
      let(:filter) { 'test' }

      it 'passes filter param to bitbucket client' do
        expect(repos).to receive(:partition).and_return([[@repo, @created_repo], [@invalid_repo]])
        expect(client).to receive(:repos).with(filter: filter, limit: 25, page_offset: 0).and_return(repos)

        get :status, params: { filter: filter }, as: :json
      end
    end
  end

  describe 'GET jobs' do
    before do
      assign_session_tokens
    end

    it 'returns a list of imported projects' do
      created_project = create(:project, import_type: 'bitbucket_server', creator_id: user.id)

      get :jobs

      expect(json_response.count).to eq(1)
      expect(json_response.first['id']).to eq(created_project.id)
      expect(json_response.first['import_status']).to eq('none')
    end
  end
end

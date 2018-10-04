require 'spec_helper'

describe Import::BitbucketServerController do
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
    before do
      allow(controller).to receive(:bitbucket_client).and_return(client)
      repo = double(name: 'my-project')
      allow(client).to receive(:repo).with(project_key, repo_slug).and_return(repo)
      assign_session_tokens
    end

    set(:project) { create(:project) }

    it 'returns the new project' do
      allow(Gitlab::BitbucketServerImport::ProjectCreator)
        .to receive(:new).with(project_key, repo_slug, anything, 'my-project', user.namespace, user, anything)
        .and_return(double(execute: project))

      post :create, project: project_key, repository: repo_slug, format: :json

      expect(response).to have_gitlab_http_status(200)
    end

    it 'returns an error when an invalid project key is used' do
      post :create, project: 'some&project'

      expect(response).to have_gitlab_http_status(422)
    end

    it 'returns an error when an invalid repository slug is used' do
      post :create, project: 'some-project', repository: 'try*this'

      expect(response).to have_gitlab_http_status(422)
    end

    it 'returns an error when the project cannot be found' do
      allow(client).to receive(:repo).with(project_key, repo_slug).and_return(nil)

      post :create, project: project_key, repository: repo_slug, format: :json

      expect(response).to have_gitlab_http_status(422)
    end

    it 'returns an error when the project cannot be saved' do
      allow(Gitlab::BitbucketServerImport::ProjectCreator)
        .to receive(:new).with(project_key, repo_slug, anything, 'my-project', user.namespace, user, anything)
        .and_return(double(execute: build(:project)))

      post :create, project: project_key, repository: repo_slug, format: :json

      expect(response).to have_gitlab_http_status(422)
    end

    it "returns an error when the server can't be contacted" do
      expect(client).to receive(:repo).with(project_key, repo_slug).and_raise(BitbucketServer::Client::ServerError)

      post :create, project: project_key, repository: repo_slug, format: :json

      expect(response).to have_gitlab_http_status(422)
    end
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

      expect(response).to have_gitlab_http_status(302)
      expect(response).to redirect_to(status_import_bitbucket_server_path)
    end

    it 'sets the session variables' do
      post :configure, personal_access_token: token, bitbucket_username: username, bitbucket_server_url: url

      expect(session[:bitbucket_server_url]).to eq(url)
      expect(session[:bitbucket_server_username]).to eq(username)
      expect(session[:bitbucket_server_personal_access_token]).to eq(token)
      expect(response).to have_gitlab_http_status(302)
      expect(response).to redirect_to(status_import_bitbucket_server_path)
    end
  end

  describe 'GET status' do
    render_views

    before do
      allow(controller).to receive(:bitbucket_client).and_return(client)

      @repo = double(slug: 'vim', project_key: 'asd', full_name: 'asd/vim', "valid?" => true, project_name: 'asd', browse_url: 'http://test', name: 'vim')
      @invalid_repo = double(slug: 'invalid', project_key: 'foobar', full_name: 'asd/foobar', "valid?" => false, browse_url: 'http://bad-repo')
      assign_session_tokens
    end

    it 'assigns repository categories' do
      created_project = create(:project, import_type: 'bitbucket_server', creator_id: user.id, import_source: 'foo/bar', import_status: 'finished')
      expect(client).to receive(:repos).and_return([@repo, @invalid_repo])

      get :status

      expect(assigns(:already_added_projects)).to eq([created_project])
      expect(assigns(:repos)).to eq([@repo])
      expect(assigns(:incompatible_repos)).to eq([@invalid_repo])
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

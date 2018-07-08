require 'spec_helper'

describe Import::BitbucketServerController do
  let(:user) { create(:user) }
  let(:project_key) { 'test-project' }
  let(:repo_slug) { 'some-repo' }

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
      assign_session_tokens
    end

    set(:project) { create(:project) }

    it 'returns the new project' do
      client = instance_double(BitbucketServer::Client)
      allow(Gitlab::BitbucketServerImport::ProjectCreator)
        .to receive(:new).with(project_key, repo_slug, anything, 'my-project', user.namespace, user, anything)
        .and_return(double(execute: project))
      repo = double(name: 'my-project')
      expect(client).to receive(:repo).with(project_key, repo_slug).and_return(repo)
      expect(controller).to receive(:bitbucket_client).and_return(client)

      post :create, project: project_key, repository: repo_slug, format: :json

      expect(response).to have_gitlab_http_status(200)
    end

    it 'returns an error when an invalid project key is used' do
    end

    it 'returns an error when an invalid repository slug is used' do
    end

    it 'returns an error when the project cannot be saved' do
    end

    it "returns an error when the server can't be contacted" do
    end
  end

  describe 'POST configure' do
    it 'sets the session variables' do
    end
  end

  describe 'GET status' do
    it 'shows the list of projects to be imported' do
    end
  end

  describe 'GET jobs' do
    it 'returns a list of imported projects' do
    end
  end
end

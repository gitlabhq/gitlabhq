require 'spec_helper'

describe Import::GithubController do
  include ImportSpecHelper

  let(:provider) { :github }

  include_context 'a GitHub-ish import controller'

  describe "GET new" do
    it_behaves_like 'a GitHub-ish import controller: GET new'

    it "redirects to GitHub for an access token if logged in with GitHub" do
      allow(controller).to receive(:logged_in_with_provider?).and_return(true)
      expect(controller).to receive(:go_to_provider_for_permissions)

      get :new
    end
  end

  describe "GET callback" do
    it "updates access token" do
      token = "asdasd12345"
      allow_any_instance_of(Gitlab::LegacyGithubImport::Client)
        .to receive(:get_token).and_return(token)
      allow_any_instance_of(Gitlab::LegacyGithubImport::Client)
        .to receive(:github_options).and_return({})
      stub_omniauth_provider('github')

      get :callback

      expect(session[:github_access_token]).to eq(token)
      expect(controller).to redirect_to(status_import_github_url)
    end
  end

  describe "POST personal_access_token" do
    it_behaves_like 'a GitHub-ish import controller: POST personal_access_token'
  end

  describe "GET status" do
    it_behaves_like 'a GitHub-ish import controller: GET status'
  end

  describe "POST create" do
    it_behaves_like 'a GitHub-ish import controller: POST create'
  end
end

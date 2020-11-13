# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::GithubController do
  include ImportSpecHelper

  let(:provider) { :github }

  include_context 'a GitHub-ish import controller'

  describe "GET new" do
    it_behaves_like 'a GitHub-ish import controller: GET new'

    it "redirects to GitHub for an access token if logged in with GitHub" do
      allow(controller).to receive(:logged_in_with_provider?).and_return(true)
      expect(controller).to receive(:go_to_provider_for_permissions).and_call_original
      allow(controller).to receive(:authorize_url).and_call_original

      get :new

      expect(response).to have_gitlab_http_status(:found)
    end

    it "prompts for an access token if GitHub not configured" do
      allow(controller).to receive(:github_import_configured?).and_return(false)
      expect(controller).not_to receive(:go_to_provider_for_permissions)

      get :new

      expect(response).to have_gitlab_http_status(:ok)
    end

    context 'when importing a CI/CD project' do
      it 'always prompts for an access token' do
        allow(controller).to receive(:github_import_configured?).and_return(true)

        get :new, params: { ci_cd_only: true }

        expect(response).to render_template(:new)
      end
    end
  end

  describe "GET callback" do
    before do
      allow(controller).to receive(:get_token).and_return(token)
      allow(controller).to receive(:oauth_options).and_return({})

      stub_omniauth_provider('github')
    end

    it "updates access token" do
      token = "asdasd12345"

      get :callback

      expect(session[:github_access_token]).to eq(token)
      expect(controller).to redirect_to(status_import_github_url)
    end
  end

  describe "POST personal_access_token" do
    it_behaves_like 'a GitHub-ish import controller: POST personal_access_token'
  end

  describe "GET status" do
    context 'when using OAuth' do
      before do
        allow(controller).to receive(:logged_in_with_provider?).and_return(true)
      end

      context 'when OAuth config is missing' do
        let(:new_import_url) { public_send("new_import_#{provider}_url") }

        before do
          allow(controller).to receive(:oauth_config).and_return(nil)
        end

        it 'returns missing config error' do
          expect(controller).to receive(:go_to_provider_for_permissions).and_call_original

          get :status

          expect(session[:"#{provider}_access_token"]).to be_nil
          expect(controller).to redirect_to(new_import_url)
          expect(flash[:alert]).to eq('Missing OAuth configuration for GitHub.')
        end
      end
    end

    context 'when feature remove_legacy_github_client is disabled' do
      before do
        stub_feature_flags(remove_legacy_github_client: false)
        session[:"#{provider}_access_token"] = 'asdasd12345'
      end

      it_behaves_like 'a GitHub-ish import controller: GET status'

      it 'uses Gitlab::LegacyGitHubImport::Client' do
        expect(controller.send(:client)).to be_instance_of(Gitlab::LegacyGithubImport::Client)
      end

      it 'fetches repos using legacy client' do
        expect_next_instance_of(Gitlab::LegacyGithubImport::Client) do |client|
          expect(client).to receive(:repos)
        end

        get :status
      end
    end

    context 'when feature remove_legacy_github_client is enabled' do
      before do
        stub_feature_flags(remove_legacy_github_client: true)
        session[:"#{provider}_access_token"] = 'asdasd12345'
      end

      it_behaves_like 'a GitHub-ish import controller: GET status'

      it 'uses Gitlab::GithubImport::Client' do
        expect(controller.send(:client)).to be_instance_of(Gitlab::GithubImport::Client)
      end

      it 'fetches repos using latest github client' do
        expect_next_instance_of(Gitlab::GithubImport::Client) do |client|
          expect(client).to receive(:each_page).with(:repos).and_return([].to_enum)
        end

        get :status
      end

      it 'concatenates list of repos from multiple pages' do
        repo_1 = OpenStruct.new(login: 'emacs', full_name: 'asd/emacs', name: 'emacs', owner: { login: 'owner' })
        repo_2 = OpenStruct.new(login: 'vim', full_name: 'asd/vim', name: 'vim', owner: { login: 'owner' })
        repos = [OpenStruct.new(objects: [repo_1]), OpenStruct.new(objects: [repo_2])].to_enum

        allow(stub_client).to receive(:each_page).and_return(repos)

        get :status, format: :json

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.dig('provider_repos').count).to eq(2)
        expect(json_response.dig('provider_repos', 0, 'id')).to eq(repo_1.id)
        expect(json_response.dig('provider_repos', 1, 'id')).to eq(repo_2.id)
      end

      context 'when filtering' do
        let(:filter) { 'test' }
        let(:user_login) { 'user' }
        let(:collaborations_subquery) { 'repo:repo1 repo:repo2' }
        let(:organizations_subquery) { 'org:org1 org:org2' }

        before do
          allow_next_instance_of(Octokit::Client) do |client|
            allow(client).to receive(:user).and_return(double(login: user_login))
          end
        end

        it 'makes request to github search api' do
          expected_query = "test in:name is:public,private user:#{user_login} #{collaborations_subquery} #{organizations_subquery}"

          expect_next_instance_of(Gitlab::GithubImport::Client) do |client|
            expect(client).to receive(:collaborations_subquery).and_return(collaborations_subquery)
            expect(client).to receive(:organizations_subquery).and_return(organizations_subquery)
            expect(client).to receive(:each_page).with(:search_repositories, expected_query).and_return([].to_enum)
          end

          get :status, params: { filter: filter }, format: :json
        end

        context 'when user input contains colons and spaces' do
          before do
            stub_client(search_repos_by_name: [])
          end

          it 'sanitizes user input' do
            filter = ' test1:test2 test3 : test4 '
            expected_filter = 'test1test2test3test4'

            get :status, params: { filter: filter }, format: :json

            expect(assigns(:filter)).to eq(expected_filter)
          end
        end

        context 'when rate limit threshold is exceeded' do
          before do
            allow(controller).to receive(:status).and_raise(Gitlab::GithubImport::RateLimitError)
          end

          it 'returns 429' do
            get :status, params: { filter: 'test' }, format: :json

            expect(response).to have_gitlab_http_status(:too_many_requests)
          end
        end
      end
    end
  end

  describe "POST create" do
    it_behaves_like 'a GitHub-ish import controller: POST create'

    it_behaves_like 'project import rate limiter'
  end

  describe "GET realtime_changes" do
    it_behaves_like 'a GitHub-ish import controller: GET realtime_changes'
  end
end

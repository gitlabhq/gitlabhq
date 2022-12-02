# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::GithubController do
  include ImportSpecHelper

  let(:provider) { :github }
  let(:new_import_url) { public_send("new_import_#{provider}_url") }

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
    context "when auth state param is missing from session" do
      it "reports an error" do
        get :callback

        expect(controller).to redirect_to(new_import_url)
        expect(flash[:alert]).to eq('Access denied to your GitHub account.')
      end
    end

    context "when auth state param is present in session" do
      let(:valid_auth_state) { "secret-state" }

      context 'when remove_legacy_github_client feature is disabled' do
        before do
          stub_feature_flags(remove_legacy_github_client: false)
          allow_next_instance_of(Gitlab::LegacyGithubImport::Client) do |client|
            allow(client).to receive(:get_token).and_return(token)
          end
          session[:github_auth_state_key] = valid_auth_state
        end

        it "updates access token if state param is valid" do
          token = "asdasd12345"

          get :callback, params: { state: valid_auth_state }

          expect(session[:github_access_token]).to eq(token)
          expect(controller).to redirect_to(status_import_github_url)
        end

        it "includes namespace_id from query params if it is present" do
          namespace_id = 1

          get :callback, params: { state: valid_auth_state, namespace_id: namespace_id }

          expect(controller).to redirect_to(status_import_github_url(namespace_id: namespace_id))
        end
      end

      it "reports an error if state param is invalid" do
        get :callback, params: { state: "different-state" }

        expect(controller).to redirect_to(new_import_url)
        expect(flash[:alert]).to eq('Access denied to your GitHub account.')
      end

      context 'when remove_legacy_github_client feature is enabled' do
        before do
          stub_feature_flags(remove_legacy_github_client: true)
          allow_next_instance_of(OAuth2::Client) do |client|
            allow(client).to receive_message_chain(:auth_code, :get_token, :token).and_return(token)
          end
          session[:github_auth_state_key] = valid_auth_state
        end

        it "updates access token if state param is valid" do
          token = "asdasd12345"

          get :callback, params: { state: valid_auth_state }

          expect(session[:github_access_token]).to eq(token)
          expect(controller).to redirect_to(status_import_github_url)
        end

        it "includes namespace_id from query params if it is present" do
          namespace_id = 1

          get :callback, params: { state: valid_auth_state, namespace_id: namespace_id }

          expect(controller).to redirect_to(status_import_github_url(namespace_id: namespace_id))
        end
      end
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
          expect(client).to receive(:repos).and_return([])
        end

        get :status
      end

      it 'gets authorization url using legacy client' do
        allow(controller).to receive(:logged_in_with_provider?).and_return(true)
        expect(controller).to receive(:go_to_provider_for_permissions).and_call_original
        expect_next_instance_of(Gitlab::LegacyGithubImport::Client) do |client|
          expect(client).to receive(:authorize_url).and_call_original
        end

        get :new
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
          expect(client).to receive(:repos).and_return([])
        end

        get :status
      end

      it 'gets authorization url using oauth client' do
        allow(controller).to receive(:logged_in_with_provider?).and_return(true)
        expect(controller).to receive(:go_to_provider_for_permissions).and_call_original
        expect_next_instance_of(OAuth2::Client) do |client|
          expect(client.auth_code).to receive(:authorize_url).and_call_original
        end

        get :new
      end

      context 'pagination' do
        context 'when no page is specified' do
          it 'requests first page' do
            expect_next_instance_of(Gitlab::GithubImport::Client) do |client|
              expect(client).to receive(:repos).with({ page: 1, per_page: 25 }).and_return([])
            end

            get :status
          end
        end

        context 'when page is specified' do
          it 'requests repos with specified page' do
            expect_next_instance_of(Octokit::Client) do |client|
              expect(client).to receive(:repos).with(nil, { page: 2, per_page: 25 }).and_return([].to_enum)
            end

            get :status, params: { page: 2 }
          end
        end
      end

      context 'when filtering' do
        let(:filter) { 'test' }
        let(:user_login) { 'user' }
        let(:collaborations_subquery) { 'repo:repo1 repo:repo2' }
        let(:organizations_subquery) { 'org:org1 org:org2' }
        let(:search_query) { "test in:name is:public,private user:#{user_login} #{collaborations_subquery} #{organizations_subquery}" }

        before do
          allow_next_instance_of(Octokit::Client) do |client|
            allow(client).to receive(:user).and_return(double(login: user_login))
          end
        end

        it 'makes request to github search api' do
          expect_next_instance_of(Octokit::Client) do |client|
            expect(client).to receive(:user).and_return({ login: user_login })
            expect(client).to receive(:search_repositories).with(search_query, { page: 1, per_page: 25 }).and_return({ items: [].to_enum })
          end

          expect_next_instance_of(Gitlab::GithubImport::Client) do |client|
            expect(client).to receive(:collaborations_subquery).and_return(collaborations_subquery)
            expect(client).to receive(:organizations_subquery).and_return(organizations_subquery)
          end

          get :status, params: { filter: filter }, format: :json
        end

        context 'pagination' do
          context 'when no page is specified' do
            it 'requests first page' do
              expect_next_instance_of(Octokit::Client) do |client|
                expect(client).to receive(:user).and_return({ login: user_login })
                expect(client).to receive(:search_repositories).with(search_query, { page: 1, per_page: 25 }).and_return({ items: [].to_enum })
              end

              expect_next_instance_of(Gitlab::GithubImport::Client) do |client|
                expect(client).to receive(:collaborations_subquery).and_return(collaborations_subquery)
                expect(client).to receive(:organizations_subquery).and_return(organizations_subquery)
              end

              get :status, params: { filter: filter }, format: :json
            end
          end

          context 'when page is specified' do
            it 'requests repos with specified page' do
              expect_next_instance_of(Octokit::Client) do |client|
                expect(client).to receive(:user).and_return({ login: user_login })
                expect(client).to receive(:search_repositories).with(search_query, { page: 2, per_page: 25 }).and_return({ items: [].to_enum })
              end

              expect_next_instance_of(Gitlab::GithubImport::Client) do |client|
                expect(client).to receive(:collaborations_subquery).and_return(collaborations_subquery)
                expect(client).to receive(:organizations_subquery).and_return(organizations_subquery)
              end

              get :status, params: { filter: filter, page: 2 }, format: :json
            end
          end
        end

        context 'when user input contains colons and spaces' do
          before do
            allow_next_instance_of(Gitlab::GithubImport::Client) do |client|
              allow(client).to receive(:search_repos_by_name).and_return(items: [])
            end
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
    let(:user) { create(:user) }

    before do
      assign_session_token(provider)
    end

    it_behaves_like 'a GitHub-ish import controller: GET realtime_changes'

    it 'includes stats in response' do
      create(:project, import_type: provider, namespace: user.namespace, import_status: :finished, import_source: 'example/repo')

      get :realtime_changes

      expect(json_response[0]).to include('stats')
      expect(json_response[0]['stats']).to include('fetched')
      expect(json_response[0]['stats']).to include('imported')
    end
  end

  describe "POST cancel" do
    let_it_be(:project) { create(:project, :import_started, import_type: 'github', import_url: 'https://fake.url') }

    context 'when project import was canceled' do
      before do
        allow(Import::Github::CancelProjectImportService)
          .to receive(:new).with(project, user)
          .and_return(double(execute: { status: :success, project: project }))
      end

      it 'returns success' do
        post :cancel, params: { project_id: project.id }

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when project import was not canceled' do
      before do
        allow(Import::Github::CancelProjectImportService)
          .to receive(:new).with(project, user)
          .and_return(double(execute: { status: :error, message: 'The import cannot be canceled because it is finished', http_status: :bad_request }))
      end

      it 'returns error' do
        post :cancel, params: { project_id: project.id }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['errors']).to eq('The import cannot be canceled because it is finished')
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::GithubController, feature_category: :import do
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

    it 'gets authorization url using oauth client' do
      allow(controller).to receive(:logged_in_with_provider?).and_return(true)
      expect(controller).to receive(:go_to_provider_for_permissions).and_call_original
      expect_next_instance_of(OAuth2::Client) do |client|
        expect(client.auth_code).to receive(:authorize_url).and_call_original
      end

      get :new
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
    shared_examples 'calls repos through Clients::Proxy with expected args' do
      it 'calls repos list from provider with expected args' do
        expect_next_instance_of(Gitlab::GithubImport::Clients::Proxy) do |client|
          expect(client).to receive(:repos)
            .with(expected_filter, expected_options)
            .and_return({ repos: [], page_info: {} })
        end

        get :status, params: params, format: :json

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['imported_projects'].size).to eq 0
        expect(json_response['provider_repos'].size).to eq 0
        expect(json_response['incompatible_repos'].size).to eq 0
        expect(json_response['page_info']).to eq({})
      end
    end

    let(:provider_token) { 'asdasd12345' }
    let(:client_auth_success) { true }
    let(:client_stub) { instance_double(Gitlab::GithubImport::Client, user: { login: 'user' }) }
    let(:params) { nil }
    let(:pagination_params) { { before: nil, after: nil } }
    let(:relation_params) { { relation_type: nil, organization_login: '' } }
    let(:provider_repos) { [] }
    let(:expected_filter) { '' }
    let(:expected_options) do
      pagination_params.merge(relation_params).merge(
        first: 25, page: 1, per_page: 25
      )
    end

    before do
      allow_next_instance_of(Gitlab::GithubImport::Clients::Proxy) do |proxy|
        if client_auth_success
          allow(proxy).to receive(:repos).and_return({ repos: provider_repos })
          allow(proxy).to receive(:client).and_return(client_stub)
        else
          allow(proxy).to receive(:repos).and_raise(Octokit::Unauthorized)
        end
      end
      session[:"#{provider}_access_token"] = provider_token
    end

    context 'with OAuth' do
      let(:provider_token) { nil }

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

    context 'with invalid access token' do
      let(:client_auth_success) { false }

      it "handles an invalid token" do
        get :status, format: :json

        expect(session[:"#{provider}_access_token"]).to be_nil
        expect(controller).to redirect_to(new_import_url)
        expect(flash[:alert]).to eq("Access denied to your #{Gitlab::ImportSources.title(provider.to_s)} account.")
      end
    end

    context 'when user has few different repos' do
      let(:repo_struct) { Struct.new(:id, :login, :full_name, :name, :owner, keyword_init: true) }
      let(:provider_repos) do
        [repo_struct.new(login: 'vim', full_name: 'asd/vim', name: 'vim', owner: { login: 'owner' })]
      end

      let!(:imported_project) do
        create(
          :project,
          import_type: provider, namespace: user.namespace,
          import_status: :finished, import_source: 'example/repo'
        )
      end

      it 'responds with expected high-level structure' do
        get :status, format: :json

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response.dig("imported_projects", 0, "id")).to eq(imported_project.id)
        expect(json_response.dig("provider_repos", 0, "id")).to eq(provider_repos[0].id)
      end
    end

    it_behaves_like 'calls repos through Clients::Proxy with expected args'

    context 'with namespace_id param' do
      let_it_be(:user) { create(:user) }

      before do
        sign_in(user)
      end

      after do
        sign_out(user)
      end

      context 'when user is allowed to create projects in this namespace' do
        let(:namespace) { create(:namespace, owner: user) }

        it 'provides namespace to the template' do
          get :status, params: { namespace_id: namespace.id }, format: :html

          expect(response).to have_gitlab_http_status :ok
          expect(assigns(:namespace)).to eq(namespace)
        end
      end

      context 'when user is not allowed to create projects in this namespace' do
        let(:namespace) { create(:namespace) }

        it 'renders 404' do
          get :status, params: { namespace_id: namespace.id }, format: :html

          expect(response).to have_gitlab_http_status :not_found
        end
      end
    end

    context 'pagination' do
      context 'when cursor is specified' do
        let(:pagination_params) { { before: nil, after: 'CURSOR' } }
        let(:params) { pagination_params }

        it_behaves_like 'calls repos through Clients::Proxy with expected args'
      end

      context 'when page is specified' do
        let(:pagination_params) { { before: nil, after: nil, page: 2 } }
        let(:params) { pagination_params }
        let(:expected_options) do
          pagination_params.merge(relation_params).merge(first: 25, page: 2, per_page: 25)
        end

        it_behaves_like 'calls repos through Clients::Proxy with expected args'
      end
    end

    context 'when relation type params present' do
      let(:organization_login) { 'test-login' }
      let(:params) { pagination_params.merge(relation_type: 'organization', organization_login: organization_login) }
      let(:pagination_defaults) { { first: 25, page: 1, per_page: 25 } }
      let(:expected_options) do
        pagination_defaults.merge(pagination_params).merge(
          relation_type: 'organization', organization_login: organization_login
        )
      end

      it_behaves_like 'calls repos through Clients::Proxy with expected args'

      context 'when organization_login is too long and with ":"' do
        let(:organization_login) { ":#{Array.new(270) { ('a'..'z').to_a.sample }.join}" }
        let(:expected_options) do
          pagination_defaults.merge(pagination_params).merge(
            relation_type: 'organization', organization_login: organization_login.slice(1, 254)
          )
        end

        it_behaves_like 'calls repos through Clients::Proxy with expected args'
      end
    end

    context 'when filtering' do
      let(:filter_param) { FFaker::Lorem.word }
      let(:params) { { filter: filter_param } }
      let(:expected_filter) { filter_param }

      it_behaves_like 'calls repos through Clients::Proxy with expected args'

      context 'with pagination' do
        context 'when before cursor present' do
          let(:pagination_params) { { before: 'before-cursor', after: nil } }
          let(:params) { { filter: filter_param }.merge(pagination_params) }

          it_behaves_like 'calls repos through Clients::Proxy with expected args'
        end

        context 'when after cursor present' do
          let(:pagination_params) { { before: nil, after: 'after-cursor' } }
          let(:params) { { filter: filter_param }.merge(pagination_params) }

          it_behaves_like 'calls repos through Clients::Proxy with expected args'
        end
      end

      context 'when user input contains colons and spaces' do
        let(:filter_param) { ' test1:test2 test3 : test4 ' }
        let(:expected_filter) { 'test1test2test3test4' }

        it_behaves_like 'calls repos through Clients::Proxy with expected args'
      end
    end

    context 'when rate limit threshold is exceeded' do
      before do
        allow(controller).to receive(:status).and_raise(Gitlab::GithubImport::RateLimitError)
      end

      it 'returns 429' do
        get :status, format: :json

        expect(response).to have_gitlab_http_status(:too_many_requests)
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

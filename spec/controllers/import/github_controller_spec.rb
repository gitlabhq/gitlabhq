# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::GithubController, feature_category: :importers do
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

      before do
        allow_next_instance_of(OAuth2::Client) do |client|
          allow(client).to receive_message_chain(:auth_code, :get_token, :token).and_return(token)
        end
        session[:github_auth_state_key] = valid_auth_state
      end

      it "reports an error if state param is invalid" do
        get :callback, params: { state: "different-state" }

        expect(controller).to redirect_to(new_import_url)
        expect(flash[:alert]).to eq('Access denied to your GitHub account.')
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

  describe "POST personal_access_token" do
    it_behaves_like 'a GitHub-ish import controller: POST personal_access_token'
  end

  describe "GET status" do
    shared_examples 'calls repos through Clients::Proxy with expected args' do
      it 'calls repos list from provider with expected args' do
        expect_next_instance_of(Gitlab::GithubImport::Clients::Proxy) do |client|
          expect(client).to receive(:repos)
            .and_return({ repos: [], page_info: {}, count: 0 })
        end

        get :status, params: params, format: :json

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['imported_projects'].size).to eq 0
        expect(json_response['provider_repos'].size).to eq 0
        expect(json_response['incompatible_repos'].size).to eq 0
        expect(json_response['page_info']).to eq({})
        expect(json_response['provider_repo_count']).to eq(0)
      end
    end

    let(:provider_token) { 'asdasd12345' }
    let(:client_auth_success) { true }
    let(:client_stub) { instance_double(Gitlab::GithubImport::Client, user: { login: 'user' }) }
    let(:params) { nil }
    let(:pagination_params) { { before: nil, after: nil } }
    let(:relation_params) { { relation_type: nil, organization_login: '' } }
    let(:provider_repos) { [] }

    before do
      allow_next_instance_of(Gitlab::GithubImport::Clients::Proxy) do |proxy|
        if client_auth_success
          allow(proxy).to receive(:repos).and_return({ repos: provider_repos })
          allow(proxy).to receive(:client).and_return(client_stub)
          allow_next_instance_of(Gitlab::GithubImport::ProjectRelationType) do |instance|
            allow(instance).to receive(:for).with('example/repo').and_return('owned')
          end
        elsif client_scope_error
          allow(proxy).to receive(:repos).and_raise(Octokit::Forbidden)
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

    context 'with invalid auth token' do
      let(:client_auth_success) { false }
      let(:client_scope_error) { false }

      it "handles the error" do
        get :status, format: :json

        expect(session[:"#{provider}_access_token"]).to be_nil
        expect(controller).to redirect_to(new_import_url)
        expect(flash[:alert]).to eq("Access denied to your #{Gitlab::ImportSources.title(provider.to_s)} account.")
      end
    end

    context 'with invalid access token' do
      let(:client_auth_success) { false }
      let(:client_scope_error) { true }
      let(:docs_link) do
        ActionController::Base.helpers.link_to(
          'Learn More',
          help_page_url(
            'user/project/import/github.md', anchor: 'use-a-github-personal-access-token'
          ),
          target: '_blank',
          rel: 'noopener noreferrer'
        )
      end

      it "handles the error" do
        get :status, format: :json

        expect(session[:"#{provider}_access_token"]).to be_nil
        expect(controller).to redirect_to(new_import_url)
        expect(flash[:alert]).to eq("Your GitHub personal access token does not have the required scope to import. " \
                                    "#{docs_link}.")
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
    end

    context 'when relation type params present' do
      let(:organization_login) { 'test-login' }
      let(:params) { pagination_params.merge(relation_type: 'organization', organization_login: organization_login) }
      let(:pagination_defaults) { { first: 25 } }

      it_behaves_like 'calls repos through Clients::Proxy with expected args'

      context 'when organization_login is too long and with ":"' do
        let(:organization_login) { ":#{Array.new(270) { ('a'..'z').to_a.sample }.join}" }

        it_behaves_like 'calls repos through Clients::Proxy with expected args'
      end
    end

    context 'when filtering' do
      let(:filter_param) { FFaker::Lorem.word }
      let(:params) { { filter: filter_param } }

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

  describe "POST create", :clean_gitlab_redis_cache do
    before do
      allow_next_instance_of(Gitlab::GithubImport::ProjectRelationType) do |instance|
        allow(instance).to receive(:for).with("#{provider_username}/vim").and_return('owned')
      end
    end

    it_behaves_like 'a GitHub-ish import controller: POST create' do
      context 'when github importer is not enabled' do
        before do
          stub_application_setting(import_sources: [])
        end

        it 'returns 404' do
          post :create, params: { target_namespace: user.namespace }, format: :json

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    it_behaves_like 'project import rate limiter'
  end

  describe "GET realtime_changes" do
    let(:user) { create(:user) }

    before do
      assign_session_token(provider)
    end

    it_behaves_like 'a GitHub-ish import controller: GET realtime_changes'

    it 'includes stats in response' do
      project = create(:project, import_type: provider, namespace: user.namespace, import_status: :finished, import_source: 'example/repo')

      ::Gitlab::GithubImport::ObjectCounter.increment(project, :issue, :imported, value: 8)

      get :realtime_changes

      expect(json_response[0]).to include('stats')
      expect(json_response[0]['stats']).to include('fetched')
      expect(json_response[0]['stats']).to include('imported')
    end
  end

  describe "GET failures" do
    let_it_be_with_reload(:project) { create(:project, import_type: 'github', import_status: :started, import_source: 'example/repo', import_url: 'https://fake.url') }
    let!(:import_failure) do
      create(:import_failure,
        project: project,
        source: 'Gitlab::GithubImport::Importer::PullRequestImporter',
        external_identifiers: { iid: 2, object_type: 'pull_request', title: 'My Pull Request' }
      )
    end

    let(:user) { project.owner }

    before do
      sign_in(user)
    end

    context 'when import is not finished' do
      it 'return bad_request' do
        get :failures, params: { project_id: project.id }

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response['message']).to eq('The import is not complete.')
      end
    end

    context 'when import is finished' do
      before do
        project.import_state.finish
      end

      it 'includes failure details in response' do
        get :failures, params: { project_id: project.id }

        expect(json_response[0]['type']).to eq('pull_request')
        expect(json_response[0]['title']).to eq('My Pull Request')
        expect(json_response[0]['provider_url']).to eq("https://fake.url/example/repo/pull/2")
        expect(json_response[0]['details']['source']).to eq(import_failure.source)
      end

      it 'paginates records' do
        issue_title = 'My Issue'

        create(
          :import_failure,
          project: project,
          source: 'Gitlab::GithubImport::Importer::IssueAndLabelLinksImporter',
          external_identifiers: { iid: 3, object_type: 'issue', title: issue_title }
        )

        get :failures, params: { project_id: project.id, page: 2, per_page: 1 }

        expect(json_response.size).to eq(1)
        expect(json_response.first['title']).to eq(issue_title)
      end
    end

    context 'when signed user is not the owner' do
      let(:user) { create(:user) }

      it 'renders 404' do
        get :failures, params: { project_id: project.id }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe "POST cancel" do
    let_it_be(:project) do
      create(
        :project, :import_started,
        import_type: 'github', import_url: 'https://fake.url', import_source: 'login/repo'
      )
    end

    let(:user) { project.owner }

    before do
      sign_in(user)
    end

    context 'when project import was canceled' do
      before do
        allow(Import::Github::CancelProjectImportService)
          .to receive(:new).with(project, user)
          .and_return(double(execute: { status: :success, project: project }))

        allow_next_instance_of(Gitlab::GithubImport::ProjectRelationType) do |instance|
          allow(instance).to receive(:for).with('login/repo').and_return('owned')
        end
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

    context 'when signed user is not the owner' do
      let(:user) { create(:user) }

      it 'renders 404' do
        post :cancel, params: { project_id: project.id }

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'POST cancel_all' do
    context 'when import is in progress' do
      it 'returns success' do
        project = create(:project, :import_scheduled, namespace: user.namespace, import_type: 'github', import_url: 'https://fake.url')
        project2 = create(:project, :import_started, namespace: user.namespace, import_type: 'github', import_url: 'https://fake2.url')

        expect(Import::Github::CancelProjectImportService)
          .to receive(:new).with(project, user)
          .and_return(double(execute: { status: :success, project: project }))

        expect(Import::Github::CancelProjectImportService)
          .to receive(:new).with(project2, user)
          .and_return(double(execute: { status: :bad_request, message: 'The import cannot be canceled because it is finished' }))

        post :cancel_all

        expect(json_response).to eq([
          {
            'id' => project.id,
            'status' => 'success'
          },
          {
            'id' => project2.id,
            'status' => 'bad_request',
            'error' => 'The import cannot be canceled because it is finished'
          }
        ])
      end
    end

    context 'when there is no imports in progress' do
      it 'returns an empty array' do
        create(:project, :import_finished, namespace: user.namespace, import_type: 'github', import_url: 'https://fake.url')

        post :cancel_all

        expect(json_response).to eq([])
      end
    end

    context 'when there is no projects created by user' do
      it 'returns an empty array' do
        other_user_project = create(:project, :import_started, import_type: 'github', import_url: 'https://fake.url')

        post :cancel_all

        expect(json_response).to eq([])
        expect(other_user_project.import_status).to eq('started')
      end
    end
  end

  describe 'GET counts' do
    let(:expected_result) do
      {
        'owned' => 3,
        'collaborated' => 2,
        'organization' => 1
      }
    end

    it 'returns repos count by type' do
      expect_next_instance_of(Gitlab::GithubImport::Clients::Proxy) do |client_proxy|
        expect(client_proxy).to receive(:count_repos_by).with('owned', user.id).and_return(3)
        expect(client_proxy).to receive(:count_repos_by).with('collaborated', user.id).and_return(2)
        expect(client_proxy).to receive(:count_repos_by).with('organization', user.id).and_return(1)
      end

      get :counts

      expect(json_response).to eq(expected_result)
    end
  end
end

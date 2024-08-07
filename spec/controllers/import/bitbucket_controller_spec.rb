# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::BitbucketController, feature_category: :importers do
  include ImportSpecHelper

  let(:user) { create(:user) }
  let(:token) { "asdasd12345" }
  let(:secret) { "sekrettt" }
  let(:refresh_token) { SecureRandom.hex(15) }
  let(:access_params) { { token: token, expires_at: nil, expires_in: nil, refresh_token: nil } }
  let(:code) { SecureRandom.hex(8) }

  def assign_session_tokens
    session[:bitbucket_token] = token
  end

  before do
    sign_in(user)
    allow(controller).to receive(:bitbucket_import_enabled?).and_return(true)
  end

  describe "GET callback" do
    before do
      session[:oauth_request_token] = {}
    end

    context "when auth state param is invalid" do
      let(:random_key) { "pure_random"  }
      let(:external_bitbucket_auth_url) { "http://fake.bitbucket.host/url" }

      it "redirects to external auth url" do
        expected_client_options = {
          site: OmniAuth::Strategies::Bitbucket.default_options[:client_options]['site'],
          authorize_url: OmniAuth::Strategies::Bitbucket.default_options[:client_options]['authorize_url'],
          token_url: OmniAuth::Strategies::Bitbucket.default_options[:client_options]['token_url']
        }

        expect(OAuth2::Client)
          .to receive(:new)
          .with(anything, anything, expected_client_options)

        allow(SecureRandom).to receive(:base64).and_return(random_key)
        allow_next_instance_of(OAuth2::Client) do |client|
          allow(client).to receive_message_chain(:auth_code, :authorize_url)
            .with(redirect_uri: users_import_bitbucket_callback_url, state: random_key)
            .and_return(external_bitbucket_auth_url)
        end

        get :callback, params: { code: code, state: "invalid-token" }

        expect(controller).to redirect_to(external_bitbucket_auth_url)
      end
    end

    context "when auth state param is valid" do
      let(:expires_at) { Time.current + 1.day }
      let(:expires_in) { 1.day }
      let(:access_token) do
        double(
          token: token,
          secret: secret,
          expires_at: expires_at,
          expires_in: expires_in,
          refresh_token: refresh_token
        )
      end

      before do
        session[:bitbucket_auth_state] = 'state'
      end

      it "updates access token" do
        allow_any_instance_of(OAuth2::Client)
          .to receive(:get_token)
          .with(hash_including(
            'grant_type' => 'authorization_code',
            'code' => code,
            'redirect_uri' => users_import_bitbucket_callback_url),
            {})
          .and_return(access_token)
        stub_omniauth_provider('bitbucket')

        get :callback, params: { code: code, state: 'state' }

        expect(session[:bitbucket_token]).to eq(token)
        expect(session[:bitbucket_refresh_token]).to eq(refresh_token)
        expect(session[:bitbucket_expires_at]).to eq(expires_at)
        expect(session[:bitbucket_expires_in]).to eq(expires_in)
        expect(controller).to redirect_to(status_import_bitbucket_url)
      end

      it "passes namespace_id query param to status if provided" do
        namespace_id = 30

        allow_any_instance_of(OAuth2::Client)
          .to receive(:get_token)
          .and_return(access_token)

        get :callback, params: { code: code, state: 'state', namespace_id: namespace_id }

        expect(controller).to redirect_to(status_import_bitbucket_url(namespace_id: namespace_id))
      end
    end
  end

  describe "GET status" do
    before do
      @repo = double(name: 'vim', slug: 'vim', owner: 'asd', full_name: 'asd/vim', clone_url: 'http://test.host/demo/url.git', 'valid?' => true)
      @invalid_repo = double(name: 'mercurialrepo', slug: 'mercurialrepo', owner: 'asd', full_name: 'asd/mercurialrepo', clone_url: 'http://test.host/demo/mercurialrepo.git', 'valid?' => false)
    end

    context "when token does not exist" do
      let(:random_key) { "pure_random"  }
      let(:external_bitbucket_auth_url) { "http://fake.bitbucket.host/url" }

      it 'redirects to authorize url with state included' do
        allow(SecureRandom).to receive(:base64).and_return(random_key)
        allow_next_instance_of(OAuth2::Client) do |client|
          allow(client).to receive_message_chain(:auth_code, :authorize_url)
            .with(redirect_uri: users_import_bitbucket_callback_url, state: random_key)
            .and_return(external_bitbucket_auth_url)
        end

        get :status, format: :json

        expect(controller).to redirect_to(external_bitbucket_auth_url)
      end
    end

    context "when token is valid" do
      before do
        assign_session_tokens
      end

      it_behaves_like 'import controller status' do
        let(:repo) { @repo }
        let(:repo_id) { @repo.full_name }
        let(:import_source) { @repo.full_name }
        let(:provider_name) { 'bitbucket' }
        let(:client_repos_field) { :repos }
      end

      it 'returns invalid repos' do
        allow_any_instance_of(Bitbucket::Client).to receive(:repos).and_return([@repo, @invalid_repo])

        get :status, format: :json

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['incompatible_repos'].length).to eq(1)
        expect(json_response.dig("incompatible_repos", 0, "id")).to eq(@invalid_repo.full_name)
        expect(json_response['provider_repos'].length).to eq(1)
        expect(json_response.dig("provider_repos", 0, "id")).to eq(@repo.full_name)
      end

      context 'when filtering' do
        let(:filter) { '<html>test</html>' }
        let(:expected_filter) { 'test' }

        subject { get :status, params: { filter: filter }, as: :json }

        it 'passes sanitized filter param to bitbucket client' do
          expect_next_instance_of(Bitbucket::Client) do |client|
            expect(client).to receive(:repos).with(filter: expected_filter).and_return([@repo])
          end

          subject
        end
      end
    end
  end

  describe "POST create", :with_current_organization do
    let(:bitbucket_username) { user.username }

    let(:bitbucket_user) do
      double(username: bitbucket_username)
    end

    let(:bitbucket_repo) do
      double(slug: "vim", owner: bitbucket_username, name: 'vim')
    end

    let(:project) { create(:project) }

    before do
      current_organization.users << user
      allow_any_instance_of(Bitbucket::Client).to receive(:repo).and_return(bitbucket_repo)
      allow_any_instance_of(Bitbucket::Client).to receive(:user).and_return(bitbucket_user)
      assign_session_tokens
    end

    it 'returns 200 response when the project is imported successfully' do
      allow(Gitlab::BitbucketImport::ProjectCreator)
        .to receive(:new).with(bitbucket_repo, bitbucket_repo.name, user.namespace, user, access_params)
        .and_return(double(execute: project))

      post :create, format: :json

      expect_snowplow_event(
        category: 'Import::BitbucketController',
        action: 'create',
        label: 'import_access_level',
        user: user,
        extra: { user_role: 'Owner', import_type: 'bitbucket' }
      )

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'returns 422 response when the project could not be imported' do
      allow(Gitlab::BitbucketImport::ProjectCreator)
        .to receive(:new).with(bitbucket_repo, bitbucket_repo.name, user.namespace, user, access_params)
        .and_return(double(execute: build(:project)))

      post :create, format: :json

      expect(response).to have_gitlab_http_status(:unprocessable_entity)
    end

    it_behaves_like 'project import rate limiter'

    context "when the repository owner is the Bitbucket user" do
      context "when the Bitbucket user and GitLab user's usernames match" do
        it "takes the current user's namespace" do
          expect(Gitlab::BitbucketImport::ProjectCreator)
            .to receive(:new).with(bitbucket_repo, bitbucket_repo.name, user.namespace, user, access_params)
            .and_return(double(execute: project))

          post :create, format: :json
        end
      end

      context "when the Bitbucket user and GitLab user's usernames don't match" do
        let(:bitbucket_username) { "someone_else" }

        it "takes the current user's namespace" do
          expect(Gitlab::BitbucketImport::ProjectCreator)
            .to receive(:new).with(bitbucket_repo, bitbucket_repo.name, user.namespace, user, access_params)
            .and_return(double(execute: project))

          post :create, format: :json
        end
      end

      context 'when the Bitbucket user is unauthorized' do
        render_views

        it 'returns unauthorized' do
          allow(controller).to receive(:current_user).and_return(user)
          allow(user).to receive(:can?).and_return(false)

          post :create, format: :json
        end
      end
    end

    context "when the repository owner is not the Bitbucket user" do
      let(:other_username) { "someone_else" }

      before do
        allow(bitbucket_repo).to receive(:owner).and_return(other_username)
      end

      context "when a namespace with the Bitbucket user's username already exists" do
        let!(:existing_namespace) { create(:group, name: other_username) }

        context "when the namespace is owned by the GitLab user" do
          before do
            existing_namespace.add_owner(user)
          end

          it "takes the existing namespace" do
            expect(Gitlab::BitbucketImport::ProjectCreator)
              .to receive(:new).with(bitbucket_repo, bitbucket_repo.name, existing_namespace, user, access_params)
              .and_return(double(execute: project))

            post :create, format: :json
          end
        end

        context "when the namespace is not owned by the GitLab user" do
          it "doesn't create a project" do
            expect(Gitlab::BitbucketImport::ProjectCreator)
              .not_to receive(:new)

            post :create, format: :json
          end
        end
      end

      context "when a namespace with the Bitbucket user's username doesn't exist" do
        context "when current user can create namespaces" do
          it "creates the namespace" do
            expect(Gitlab::BitbucketImport::ProjectCreator)
              .to receive(:new).and_return(double(execute: project))

            expect { post :create, format: :json }.to change(Namespace, :count).by(1)
          end

          it "takes the new namespace" do
            expect(Gitlab::BitbucketImport::ProjectCreator)
              .to receive(:new).with(bitbucket_repo, bitbucket_repo.name, an_instance_of(Group), user, access_params)
              .and_return(double(execute: project))

            post :create, format: :json
          end
        end

        context "when current user can't create namespaces" do
          before do
            user.update_attribute(:can_create_group, false)
          end

          it "doesn't create the namespace" do
            expect(Gitlab::BitbucketImport::ProjectCreator)
              .to receive(:new).and_return(double(execute: project))

            expect { post :create, format: :json }.not_to change(Namespace, :count)

            expect_snowplow_event(
              category: 'Import::BitbucketController',
              action: 'create',
              label: 'import_access_level',
              user: user,
              extra: { user_role: 'Owner', import_type: 'bitbucket' }
            )
          end

          it "takes the current user's namespace" do
            expect(Gitlab::BitbucketImport::ProjectCreator)
              .to receive(:new).with(bitbucket_repo, bitbucket_repo.name, user.namespace, user, access_params)
              .and_return(double(execute: project))

            post :create, format: :json
          end
        end
      end

      context "when exceptions occur" do
        shared_examples "handles exceptions" do
          it "logs an exception" do
            expect(Bitbucket::Client).to receive(:new).and_raise(error)
            expect(controller).to receive(:log_exception)

            post :create, format: :json
          end
        end

        context "for OAuth2 errors" do
          let(:fake_response) { double('Faraday::Response', headers: {}, body: '', status: 403) }
          let(:error) { OAuth2::Error.new(OAuth2::Response.new(fake_response)) }

          it_behaves_like "handles exceptions"
        end

        context "for Bitbucket errors" do
          let(:error) { Bitbucket::Error::Unauthorized.new("error") }

          it_behaves_like "handles exceptions"
        end
      end
    end

    context 'user has chosen an existing nested namespace and name for the project' do
      let(:parent_namespace) { create(:group, name: 'foo') }
      let(:nested_namespace) { create(:group, name: 'bar', parent: parent_namespace) }
      let(:test_name) { 'test_name' }

      before do
        parent_namespace.add_owner(user)
        nested_namespace.add_owner(user)
      end

      it 'takes the selected namespace and name' do
        expect(Gitlab::BitbucketImport::ProjectCreator)
          .to receive(:new).with(bitbucket_repo, test_name, nested_namespace, user, access_params)
            .and_return(double(execute: project))

        post :create, params: { target_namespace: nested_namespace.full_path, new_name: test_name }, format: :json
      end
    end

    context 'user has chosen a non-existent nested namespaces and name for the project' do
      let(:test_name) { 'test_name' }

      it 'takes the selected namespace and name' do
        expect(Gitlab::BitbucketImport::ProjectCreator)
          .to receive(:new).with(bitbucket_repo, test_name, kind_of(Namespace), user, access_params)
            .and_return(double(execute: project))

        post :create, params: { target_namespace: 'foo/bar', new_name: test_name }, format: :json
      end

      it 'creates the namespaces' do
        allow(Gitlab::BitbucketImport::ProjectCreator)
          .to receive(:new).with(bitbucket_repo, test_name, kind_of(Namespace), user, access_params)
            .and_return(double(execute: project))

        expect { post :create, params: { target_namespace: 'foo/bar', new_name: test_name }, format: :json }
          .to change { Namespace.count }.by(2)
      end

      it 'new namespace has the right parent' do
        allow(Gitlab::BitbucketImport::ProjectCreator)
          .to receive(:new).with(bitbucket_repo, test_name, kind_of(Namespace), user, access_params)
            .and_return(double(execute: project))

        post :create, params: { target_namespace: 'foo/bar', new_name: test_name }, format: :json

        expect(Namespace.find_by_path_or_name('bar').parent.path).to eq('foo')
      end
    end

    context 'user has chosen existent and non-existent nested namespaces and name for the project' do
      let(:test_name) { 'test_name' }
      let!(:parent_namespace) { create(:group, name: 'foo') }

      before do
        parent_namespace.add_owner(user)
      end

      it 'takes the selected namespace and name' do
        expect(Gitlab::BitbucketImport::ProjectCreator)
          .to receive(:new).with(bitbucket_repo, test_name, kind_of(Namespace), user, access_params)
            .and_return(double(execute: project))

        post :create, params: { target_namespace: 'foo/foobar/bar', new_name: test_name }, format: :json
      end

      it 'creates the namespaces' do
        allow(Gitlab::BitbucketImport::ProjectCreator)
          .to receive(:new).with(bitbucket_repo, test_name, kind_of(Namespace), user, access_params)
            .and_return(double(execute: project))

        expect { post :create, params: { target_namespace: 'foo/foobar/bar', new_name: test_name }, format: :json }
          .to change { Namespace.count }.by(2)
      end
    end

    context 'when user can not create projects in the chosen namespace' do
      it 'returns 422 response' do
        other_namespace = create(:group, name: 'other_namespace')

        post :create, params: { target_namespace: other_namespace.name }, format: :json

        expect(response).to have_gitlab_http_status(:unprocessable_entity)

        expect_snowplow_event(
          category: 'Import::BitbucketController',
          action: 'create',
          label: 'import_access_level',
          user: user,
          extra: { user_role: 'Not a member', import_type: 'bitbucket' }
        )
      end
    end

    context 'when user can not import projects' do
      let!(:other_namespace) { create(:group, name: 'other_namespace', developers: user) }

      it 'returns 422 response' do
        post :create, params: { target_namespace: other_namespace.name }, format: :json

        expect(response).to have_gitlab_http_status(:unprocessable_entity)
        expect(response.parsed_body['errors']).to eq(s_('BitbucketImport|You are not allowed to import projects in this namespace.'))
      end
    end
  end
end

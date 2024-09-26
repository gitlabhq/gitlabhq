# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::EnvironmentsController, feature_category: :continuous_delivery do
  include KubernetesHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:maintainer) { create(:user, name: 'main-dos', maintainer_of: project) }
  let_it_be(:reporter) { create(:user, name: 'repo-dos', reporter_of: project) }

  let(:user) { maintainer }

  let!(:environment) { create(:environment, name: 'production', project: project) }

  before do
    sign_in(user)
  end

  describe 'GET index' do
    context 'when a request for the HTML is made' do
      it 'responds with status code 200' do
        get :index, params: environment_params

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'expires etag cache to force reload environments list' do
        expect_any_instance_of(Gitlab::EtagCaching::Store)
          .to receive(:touch).with(project_environments_path(project, format: :json))

        get :index, params: environment_params
      end

      it_behaves_like 'tracking unique visits', :index do
        let(:request_params) { environment_params }
        let(:target_id) { 'users_visiting_environments_pages' }
      end
    end

    context 'when requesting JSON response for folders' do
      before do
        allow_any_instance_of(Environment).to receive(:has_terminals?).and_return(true)
        allow_any_instance_of(Environment).to receive(:rollout_status).and_return(kube_deployment_rollout_status)

        create(:environment, project: project, name: 'staging/review-1', state: :available)
        create(:environment, project: project, name: 'staging/review-2', state: :available)
        create(:environment, project: project, name: 'staging/review-3', state: :stopped)
      end

      let(:environments) { json_response['environments'] }

      context 'with default parameters' do
        subject { get :index, params: environment_params(format: :json) }

        it 'responds with a flat payload describing available environments' do
          subject

          expect(environments.count).to eq 3
          expect(environments.first).to include('name' => 'production', 'name_without_type' => 'production')
          expect(environments.second).to include('name' => 'staging/review-1', 'name_without_type' => 'review-1')
          expect(environments.third).to include('name' => 'staging/review-2', 'name_without_type' => 'review-2')
          expect(json_response['available_count']).to eq 3
          expect(json_response['stopped_count']).to eq 1
        end

        it 'handles search option properly' do
          get :index, params: environment_params(format: :json, search: 'staging/r')

          expect(environments.map { |env| env['name'] }).to contain_exactly('staging/review-1', 'staging/review-2')
          expect(json_response['available_count']).to eq 2
          expect(json_response['stopped_count']).to eq 1
        end

        it 'ignores search option if is shorter than a minimum' do
          get :index, params: environment_params(format: :json, search: 'st')

          expect(environments.map { |env| env['name'] }).to contain_exactly('production', 'staging/review-1', 'staging/review-2')
          expect(json_response['available_count']).to eq 3
          expect(json_response['stopped_count']).to eq 1
        end

        it 'supports search within environment folder name' do
          create(:environment, project: project, name: 'review-app', state: :available)

          get :index, params: environment_params(format: :json, search: 'review')

          expect(environments.map { |env| env['name'] }).to contain_exactly('review-app', 'staging/review-1', 'staging/review-2')
          expect(json_response['available_count']).to eq 3
          expect(json_response['stopped_count']).to eq 1
        end

        context 'can access stop stale environments feature' do
          it 'maintainers can access the feature' do
            get :index, params: environment_params(format: :json)

            expect(json_response['can_stop_stale_environments']).to be_truthy
          end

          context 'when user is a reporter' do
            let(:user) { reporter }

            it 'reporters cannot access the feature' do
              get :index, params: environment_params(format: :json)

              expect(json_response['can_stop_stale_environments']).to be_falsey
            end
          end
        end

        it 'sets the polling interval header' do
          subject

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.headers['Poll-Interval']).to eq("3000")
        end

        context 'validates latest deployment' do
          let_it_be(:test_environment) do
            create(:environment, project: project, name: 'staging/review-4', state: :available)
          end

          before do
            create_list(:deployment, 2, :success, environment: test_environment, project: project)
          end

          it 'responds with the latest deployment for the environment' do
            subject

            environment = environments.find { |env| env['id'] == test_environment.id }
            expect(environment['last_deployment']['id']).to eq(test_environment.deployments.last.id)
          end
        end
      end

      context 'when a folder-based nested structure is requested' do
        before do
          get :index, params: environment_params(format: :json, nested: true)
        end

        it 'responds with a payload containing the latest environment for each folder' do
          expect(environments.count).to eq 2
          expect(environments.first['name']).to eq 'production'
          expect(environments.second['name']).to eq 'staging'
          expect(environments.second['size']).to eq 2
          expect(environments.second['latest']['name']).to eq 'staging/review-2'
        end
      end

      context 'when requesting available environments scope' do
        before do
          get :index, params: environment_params(format: :json, nested: true, scope: :available)
        end

        it 'responds with a payload describing available environments' do
          expect(environments.count).to eq 2
          expect(environments.first['name']).to eq 'production'
          expect(environments.first['latest']['rollout_status']).to be_present
          expect(environments.second['name']).to eq 'staging'
          expect(environments.second['size']).to eq 2
          expect(environments.second['latest']['name']).to eq 'staging/review-2'
          expect(environments.second['latest']['rollout_status']).to be_present
        end

        it 'contains values describing environment scopes sizes' do
          expect(json_response['available_count']).to eq 3
          expect(json_response['stopped_count']).to eq 1
        end
      end

      context 'when requesting stopped environments scope' do
        before do
          get :index, params: environment_params(format: :json, nested: true, scope: :stopped)
        end

        it 'responds with a payload describing stopped environments' do
          expect(environments.count).to eq 1
          expect(environments.first['name']).to eq 'staging'
          expect(environments.first['size']).to eq 1
          expect(environments.first['latest']['name']).to eq 'staging/review-3'
        end

        it 'contains values describing environment scopes sizes' do
          expect(json_response['available_count']).to eq 3
          expect(json_response['stopped_count']).to eq 1
        end
      end
    end
  end

  describe 'GET folder' do
    context 'when using default format' do
      it 'responds with HTML' do
        get :folder, params: {
          namespace_id: project.namespace,
          project_id: project,
          id: 'staging-1.0'
        }

        expect(response).to have_gitlab_http_status(:ok)
        expect(response).to render_template 'folder'
      end

      it_behaves_like 'tracking unique visits', :folder do
        let(:request_params) do
          {
            namespace_id: project.namespace,
            project_id: project,
            id: 'staging-1.0'
          }
        end

        let(:target_id) { 'users_visiting_environments_pages' }
      end
    end

    context 'when using JSON format' do
      before do
        create(:environment, project: project, name: 'staging-1.0/review', state: :available)
        create(:environment, project: project, name: 'staging-1.0/zzz', state: :available)
      end

      let(:environments) { json_response['environments'] }

      it 'sorts the subfolders lexicographically' do
        get :folder, params: {
          namespace_id: project.namespace,
          project_id: project,
          id: 'staging-1.0'
        }, format: :json

        expect(response).to be_ok
        expect(response).not_to render_template 'folder'
        expect(json_response['environments'][0])
          .to include('name' => 'staging-1.0/review', 'name_without_type' => 'review')
        expect(json_response['environments'][1])
          .to include('name' => 'staging-1.0/zzz', 'name_without_type' => 'zzz')
      end

      it 'handles search option properly' do
        get(:folder, params: {
          namespace_id: project.namespace,
          project_id: project,
          id: 'staging-1.0',
          search: 'staging-1.0/z'
        }, format: :json)

        expect(environments.map { |env| env['name'] }).to eq(['staging-1.0/zzz'])
        expect(json_response['available_count']).to eq 1
        expect(json_response['stopped_count']).to eq 0
      end
    end
  end

  describe 'GET k8s' do
    context 'with valid id' do
      it 'responds with a status code 200' do
        get :k8s, params: environment_params

        expect(response).to be_ok
      end
    end

    context 'with invalid id' do
      it 'responds with a status code 404' do
        params = environment_params
        params[:id] = non_existing_record_id
        get :k8s, params: params

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET show' do
    context 'with valid id' do
      it 'responds with a status code 200' do
        get :show, params: environment_params

        expect(response).to be_ok
      end

      it_behaves_like 'tracking unique visits', :show do
        let(:request_params) { environment_params }
        let(:target_id) { 'users_visiting_environments_pages' }
      end

      it 'sets the kas cookie if the request format is html' do
        allow(::Gitlab::Kas::UserAccess).to receive(:enabled?).and_return(true)
        get :show, params: environment_params

        expect(
          request.env['action_dispatch.cookies'][Gitlab::Kas::COOKIE_KEY]
        ).to be_present
      end

      it 'does not set the kas_cookie if the request format is not html' do
        allow(::Gitlab::Kas::UserAccess).to receive(:enabled?).and_return(true)
        get :show, params: environment_params(format: :json)

        expect(
          request.env['action_dispatch.cookies'][Gitlab::Kas::COOKIE_KEY]
        ).to be_nil
      end
    end

    context 'with invalid id' do
      it 'responds with a status code 404' do
        params = environment_params
        params[:id] = non_existing_record_id
        get :show, params: params

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET new' do
    it 'responds with a status code 200' do
      get :new, params: environment_params

      expect(response).to be_ok
    end

    it_behaves_like 'tracking unique visits', :new do
      let(:request_params) { environment_params }
      let(:target_id) { 'users_visiting_environments_pages' }
    end
  end

  describe 'GET edit' do
    it 'responds with a status code 200' do
      get :edit, params: environment_params

      expect(response).to be_ok
    end

    it_behaves_like 'tracking unique visits', :edit do
      let(:request_params) { environment_params }
      let(:target_id) { 'users_visiting_environments_pages' }
    end
  end

  describe 'PATCH #update' do
    subject { patch :update, params: params }

    context "when environment params are valid" do
      let(:params) { environment_params.merge(environment: { external_url: 'https://git.gitlab.com' }) }

      it 'returns ok and the path to the newly created environment' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['path']).to eq("/#{project.full_path}/-/environments/#{environment.id}")
      end

      it_behaves_like 'tracking unique visits', :update do
        let(:request_params) { params }
        let(:target_id) { 'users_visiting_environments_pages' }
      end
    end

    context "when environment params are invalid" do
      let(:params) { environment_params.merge(environment: { external_url: 'javascript:alert("hello")' }) }

      it 'returns bad request' do
        subject

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when name is passed' do
      let(:params) { environment_params.merge(environment: { name: "new name" }) }

      it 'ignores name' do
        expect do
          subject
        end.not_to change { environment.reload.name }
      end
    end
  end

  describe 'PATCH #stop' do
    subject { patch :stop, params: environment_params(format: :json) }

    context 'when env not available' do
      it 'returns 404' do
        allow_any_instance_of(Environment).to receive(:available?) { false }

        subject

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when stop action' do
      it 'returns job url for a stop action when job is build' do
        action = create(:ci_build, :manual)

        allow_next_instance_of(Environments::StopService) do |service|
          response = ServiceResponse.success(payload: { environment: environment, actions: [action] })

          allow(service).to receive(:execute).with(environment).and_return(response)
        end

        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq(
          { 'redirect_url' =>
              project_job_url(project, action) })
      end

      it 'returns pipeline url for a stop action when job is bridge' do
        action = create(:ci_bridge, :manual)

        allow_next_instance_of(Environments::StopService) do |service|
          response = ServiceResponse.success(payload: { environment: environment, actions: [action] })

          allow(service).to receive(:execute).with(environment).and_return(response)
        end

        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq(
          { 'redirect_url' =>
              project_job_url(project, action) })
      end

      it 'returns environment url for multiple stop actions' do
        actions = create_list(:ci_build, 2, :manual)

        allow_next_instance_of(Environments::StopService) do |service|
          response = ServiceResponse.success(payload: { environment: environment, actions: actions })

          allow(service).to receive(:execute).with(environment).and_return(response)
        end

        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq(
          { 'redirect_url' =>
              project_environment_url(project, environment) })
      end

      it 'returns 403 if there was an error stopping the environment' do
        allow_next_instance_of(Environments::StopService) do |service|
          response = ServiceResponse.error(message: 'error message')

          allow(service).to receive(:execute).with(environment).and_return(response)
        end

        subject

        expect(response).to have_gitlab_http_status(:forbidden)
      end

      it_behaves_like 'tracking unique visits', :stop do
        let(:request_params) { environment_params(format: :json) }
        let(:target_id) { 'users_visiting_environments_pages' }
      end
    end

    context 'when no stop action' do
      it 'returns env url' do
        allow_next_instance_of(Environments::StopService) do |service|
          response = ServiceResponse.success(payload: { environment: environment, actions: [] })

          allow(service).to receive(:execute).with(environment).and_return(response)
        end

        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq(
          { 'redirect_url' =>
              project_environment_url(project, environment) })
      end
    end
  end

  describe 'POST #cancel_auto_stop' do
    subject { post :cancel_auto_stop, params: params }

    let(:params) { environment_params }

    context 'when environment is set as auto-stop' do
      let(:environment) { create(:environment, :will_auto_stop, name: 'staging', project: project) }

      it_behaves_like 'successful response for #cancel_auto_stop'

      it_behaves_like 'tracking unique visits', :cancel_auto_stop do
        let(:request_params) { environment_params }
        let(:target_id) { 'users_visiting_environments_pages' }
      end

      context 'when user is reporter' do
        let(:user) { reporter }

        it 'shows NOT Found' do
          subject

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'when environment is not set as auto-stop' do
      let(:environment) { create(:environment, name: 'staging', project: project) }

      it_behaves_like 'failed response for #cancel_auto_stop' do
        let(:message) { 'the environment is not set as auto stop' }
      end
    end
  end

  describe 'GET #terminal' do
    context 'with valid id' do
      it 'responds with a status code 200' do
        get :terminal, params: environment_params

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'loads the terminals for the environment' do
        # In EE we have to stub EE::Environment since it overwrites the
        # "terminals" method.
        expect_any_instance_of(Gitlab.ee? ? EE::Environment : Environment)
          .to receive(:terminals)

        get :terminal, params: environment_params
      end

      it_behaves_like 'tracking unique visits', :terminal do
        let(:request_params) { environment_params }
        let(:target_id) { 'users_visiting_environments_pages' }
      end
    end

    context 'with invalid id' do
      it 'responds with a status code 404' do
        get :terminal, params: environment_params(id: 666)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET #terminal_websocket_authorize' do
    context 'with valid workhorse signature' do
      before do
        allow(Gitlab::Workhorse).to receive(:verify_api_request!).and_return(nil)
      end

      context 'and valid id' do
        it 'returns the first terminal for the environment' do
          # In EE we have to stub EE::Environment since it overwrites the
          # "terminals" method.
          expect_any_instance_of(Gitlab.ee? ? EE::Environment : Environment)
            .to receive(:terminals)
            .and_return([:fake_terminal])

          expect(Gitlab::Workhorse)
            .to receive(:channel_websocket)
            .with(:fake_terminal)
            .and_return(workhorse: :response)

          get :terminal_websocket_authorize, params: environment_params

          expect(response).to have_gitlab_http_status(:ok)
          expect(response.headers["Content-Type"]).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
          expect(response.body).to eq('{"workhorse":"response"}')
        end
      end

      context 'and invalid id' do
        it 'returns 404' do
          get :terminal_websocket_authorize, params: environment_params(id: 666)

          expect(response).to have_gitlab_http_status(:not_found)
        end
      end
    end

    context 'with invalid workhorse signature' do
      it 'aborts with an exception' do
        allow(Gitlab::Workhorse).to receive(:verify_api_request!).and_raise(JWT::DecodeError)

        expect { get :terminal_websocket_authorize, params: environment_params }.to raise_error(JWT::DecodeError)
        # controller tests don't set the response status correctly. It's enough
        # to check that the action raised an exception
      end
    end
  end

  describe 'GET #search' do
    before do
      create(:environment, name: 'staging', project: project)
      create(:environment, name: 'review/patch-1', project: project)
      create(:environment, name: 'review/patch-2', project: project)
    end

    let(:query) { 'pro' }

    it 'responds with status code 200' do
      get :search, params: environment_params(format: :json, query: query)

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'returns matched results' do
      get :search, params: environment_params(format: :json, query: query)

      expect(json_response).to contain_exactly('production')
    end

    context 'when query is review' do
      let(:query) { 'review' }

      it 'returns matched results' do
        get :search, params: environment_params(format: :json, query: query)

        expect(json_response).to contain_exactly('review/patch-1', 'review/patch-2')
      end
    end

    context 'when query is empty' do
      let(:query) { '' }

      it 'returns matched results' do
        get :search, params: environment_params(format: :json, query: query)

        expect(json_response)
          .to contain_exactly('production', 'staging', 'review/patch-1', 'review/patch-2')
      end
    end

    context 'when query is review/patch-3' do
      let(:query) { 'review/patch-3' }

      it 'responds with status code 204' do
        get :search, params: environment_params(format: :json, query: query)

        expect(response).to have_gitlab_http_status(:no_content)
      end
    end

    context 'when query is partially matched in the middle of environment name' do
      let(:query) { 'patch' }

      it 'responds with status code 204' do
        get :search, params: environment_params(format: :json, query: query)

        expect(response).to have_gitlab_http_status(:no_content)
      end
    end

    context 'when query contains a wildcard character' do
      let(:query) { 'review%' }

      it 'prevents wildcard injection' do
        get :search, params: environment_params(format: :json, query: query)

        expect(response).to have_gitlab_http_status(:no_content)
      end
    end

    context 'when query matches case insensitively' do
      let(:query) { 'Prod' }

      it 'returns matched results' do
        get :search, params: environment_params(format: :json, query: query)

        expect(json_response).to contain_exactly('production')
      end
    end
  end

  describe 'POST #create' do
    subject { post :create, params: params }

    context "when environment params are valid" do
      let(:params) { { namespace_id: project.namespace, project_id: project, environment: { name: 'foo', external_url: 'https://foo.example.com' } } }

      it 'returns ok and the path to the newly created environment' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response['path']).to eq("/#{project.full_path}/-/environments/#{json_response['environment']['id']}")
      end

      it_behaves_like 'tracking unique visits', :create do
        let(:request_params) { params }
        let(:target_id) { 'users_visiting_environments_pages' }
      end
    end

    context "when environment params are invalid" do
      let(:params) { { namespace_id: project.namespace, project_id: project, environment: { name: 'foo/', external_url: '/foo.example.com' } } }

      it 'returns bad request' do
        subject

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end
  end

  def environment_params(opts = {})
    opts.reverse_merge(namespace_id: project.namespace, project_id: project, id: environment.id)
  end
end

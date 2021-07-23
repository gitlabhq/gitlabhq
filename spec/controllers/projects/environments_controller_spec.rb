# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::EnvironmentsController do
  include MetricsDashboardHelpers
  include KubernetesHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:maintainer) { create(:user, name: 'main-dos').tap { |u| project.add_maintainer(u) } }
  let_it_be(:reporter) { create(:user, name: 'repo-dos').tap { |u| project.add_reporter(u) } }

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
    end

    context 'when requesting JSON response for folders' do
      before do
        allow_any_instance_of(Environment).to receive(:has_terminals?).and_return(true)
        allow_any_instance_of(Environment).to receive(:rollout_status).and_return(kube_deployment_rollout_status)

        create(:environment, project: project,
                             name: 'staging/review-1',
                             state: :available)

        create(:environment, project: project,
                             name: 'staging/review-2',
                             state: :available)

        create(:environment, project: project,
                             name: 'staging/review-3',
                             state: :stopped)
      end

      let(:environments) { json_response['environments'] }

      context 'with default parameters' do
        before do
          get :index, params: environment_params(format: :json)
        end

        it 'responds with a flat payload describing available environments' do
          expect(environments.count).to eq 3
          expect(environments.first).to include('name' => 'production', 'name_without_type' => 'production')
          expect(environments.second).to include('name' => 'staging/review-1', 'name_without_type' => 'review-1')
          expect(environments.third).to include('name' => 'staging/review-2', 'name_without_type' => 'review-2')
          expect(json_response['available_count']).to eq 3
          expect(json_response['stopped_count']).to eq 1
        end

        it 'sets the polling interval header' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(response.headers['Poll-Interval']).to eq("3000")
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
    before do
      create(:environment, project: project,
                           name: 'staging-1.0/review',
                           state: :available)
      create(:environment, project: project,
                           name: 'staging-1.0/zzz',
                           state: :available)
    end

    context 'when using default format' do
      it 'responds with HTML' do
        get :folder, params: {
                       namespace_id: project.namespace,
                       project_id: project,
                       id: 'staging-1.0'
                     }

        expect(response).to be_ok
        expect(response).to render_template 'folder'
      end
    end

    context 'when using JSON format' do
      it 'sorts the subfolders lexicographically' do
        get :folder, params: {
                       namespace_id: project.namespace,
                       project_id: project,
                       id: 'staging-1.0'
                     },
                     format: :json

        expect(response).to be_ok
        expect(response).not_to render_template 'folder'
        expect(json_response['environments'][0])
          .to include('name' => 'staging-1.0/review', 'name_without_type' => 'review')
        expect(json_response['environments'][1])
          .to include('name' => 'staging-1.0/zzz', 'name_without_type' => 'zzz')
      end
    end
  end

  describe 'GET show' do
    context 'with valid id' do
      it 'responds with a status code 200' do
        get :show, params: environment_params

        expect(response).to be_ok
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

  describe 'GET edit' do
    it 'responds with a status code 200' do
      get :edit, params: environment_params

      expect(response).to be_ok
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
    end

    context "when environment params are invalid" do
      let(:params) { environment_params.merge(environment: { name: '/foo/', external_url: '/git.gitlab.com' }) }

      it 'returns bad request' do
        subject

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end
  end

  describe 'PATCH #stop' do
    context 'when env not available' do
      it 'returns 404' do
        allow_any_instance_of(Environment).to receive(:available?) { false }

        patch :stop, params: environment_params(format: :json)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when stop action' do
      it 'returns action url' do
        action = create(:ci_build, :manual)

        allow_any_instance_of(Environment)
          .to receive_messages(available?: true, stop_with_action!: action)

        patch :stop, params: environment_params(format: :json)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to eq(
          { 'redirect_url' =>
              project_job_url(project, action) })
      end
    end

    context 'when no stop action' do
      it 'returns env url' do
        allow_any_instance_of(Environment)
          .to receive_messages(available?: true, stop_with_action!: nil)

        patch :stop, params: environment_params(format: :json)

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

  describe 'GET #metrics_redirect' do
    it 'redirects to metrics dashboard page' do
      get :metrics_redirect, params: { namespace_id: project.namespace, project_id: project }

      expect(response).to redirect_to(project_metrics_dashboard_path(project))
    end
  end

  describe 'GET #metrics' do
    before do
      allow(controller).to receive(:environment).and_return(environment)
    end

    context 'when environment has no metrics' do
      it 'redirects to metrics dashboard page' do
        expect(environment).not_to receive(:metrics)

        get :metrics, params: environment_params

        expect(response).to redirect_to(project_metrics_dashboard_path(project, environment: environment))
      end

      context 'when requesting metrics as JSON' do
        it 'returns a metrics JSON document' do
          expect(environment).to receive(:metrics).and_return(nil)

          get :metrics, params: environment_params(format: :json)

          expect(response).to have_gitlab_http_status(:no_content)
          expect(json_response).to eq({})
        end
      end
    end

    context 'when environment has some metrics' do
      before do
        expect(environment).to receive(:metrics).and_return({
          success: true,
          metrics: {},
          last_update: 42
        })
      end

      it 'returns a metrics JSON document' do
        get :metrics, params: environment_params(format: :json)

        expect(response).to be_ok
        expect(json_response['success']).to be(true)
        expect(json_response['metrics']).to eq({})
        expect(json_response['last_update']).to eq(42)
      end
    end

    context 'permissions' do
      before do
        allow(controller).to receive(:can?).and_return true
      end

      it 'checks :metrics_dashboard ability' do
        expect(controller).to receive(:can?).with(anything, :metrics_dashboard, anything)

        get :metrics, params: environment_params
      end
    end

    context 'with anonymous user and public dashboard visibility' do
      let(:project) { create(:project, :public) }
      let(:user) { create(:user) }

      it 'redirects to metrics dashboard page' do
        project.project_feature.update!(metrics_dashboard_access_level: ProjectFeature::ENABLED)

        get :metrics, params: environment_params

        expect(response).to redirect_to(project_metrics_dashboard_path(project, environment: environment))
      end
    end
  end

  describe 'GET #additional_metrics' do
    let(:window_params) { { start: '1554702993.5398998', end: '1554717396.996232' } }

    before do
      allow(controller).to receive(:environment).and_return(environment)
    end

    context 'when environment has no metrics' do
      before do
        expect(environment).to receive(:additional_metrics).and_return(nil)
      end

      context 'when requesting metrics as JSON' do
        it 'returns a metrics JSON document' do
          additional_metrics(window_params)

          expect(response).to have_gitlab_http_status(:no_content)
          expect(json_response).to eq({})
        end
      end
    end

    context 'when environment has some metrics' do
      before do
        expect(environment)
          .to receive(:additional_metrics)
                .and_return({
                              success: true,
                              data: {},
                              last_update: 42
                            })
      end

      it 'returns a metrics JSON document' do
        additional_metrics(window_params)

        expect(response).to be_ok
        expect(json_response['success']).to be(true)
        expect(json_response['data']).to eq({})
        expect(json_response['last_update']).to eq(42)
      end
    end

    context 'when time params are missing' do
      it 'raises an error when window params are missing' do
        expect { additional_metrics }
        .to raise_error(ActionController::ParameterMissing)
      end
    end

    context 'when only one time param is provided' do
      it 'raises an error when start is missing' do
        expect { additional_metrics(end: '1552647300.651094') }
          .to raise_error(ActionController::ParameterMissing)
      end

      it 'raises an error when end is missing' do
        expect { additional_metrics(start: '1552647300.651094') }
          .to raise_error(ActionController::ParameterMissing)
      end
    end

    context 'permissions' do
      before do
        allow(controller).to receive(:can?).and_return true
      end

      it 'checks :metrics_dashboard ability' do
        expect(controller).to receive(:can?).with(anything, :metrics_dashboard, anything)

        get :metrics, params: environment_params
      end
    end

    context 'with anonymous user and public dashboard visibility' do
      let(:project) { create(:project, :public) }
      let(:user) { create(:user) }

      it 'does not fail' do
        allow(environment)
          .to receive(:additional_metrics)
          .and_return({
            success: true,
            data: {},
            last_update: 42
          })
        project.project_feature.update!(metrics_dashboard_access_level: ProjectFeature::ENABLED)

        additional_metrics(window_params)

        expect(response).to have_gitlab_http_status(:ok)
      end
    end
  end

  describe 'GET #metrics_dashboard' do
    let(:metrics_dashboard_req_params) { environment_params(dashboard_params) }

    shared_examples_for '200 response' do
      it_behaves_like 'GET #metrics_dashboard correctly formatted response' do
        let(:expected_keys) { %w(dashboard status metrics_data) }
        let(:status_code) { :ok }
      end
    end

    shared_examples_for 'error response' do |status_code|
      it_behaves_like 'GET #metrics_dashboard correctly formatted response' do
        let(:expected_keys) { %w(message status) }
        let(:status_code) { status_code }
      end
    end

    shared_examples_for 'includes all dashboards' do
      it 'includes info for all findable dashboard' do
        get :metrics_dashboard, params: environment_params(dashboard_params)

        expect(json_response).to have_key('all_dashboards')
        expect(json_response['all_dashboards']).to be_an_instance_of(Array)
        expect(json_response['all_dashboards']).to all( include('path', 'default', 'display_name') )
      end
    end

    shared_examples_for 'the default dashboard' do
      it_behaves_like 'includes all dashboards'
      it_behaves_like 'GET #metrics_dashboard for dashboard', 'Environment metrics'
    end

    shared_examples_for 'the specified dashboard' do |expected_dashboard|
      it_behaves_like 'includes all dashboards'

      it_behaves_like 'GET #metrics_dashboard for dashboard', expected_dashboard

      context 'when the dashboard cannot not be processed' do
        before do
          allow(YAML).to receive(:safe_load).and_return({})
        end

        it_behaves_like 'error response', :unprocessable_entity
      end
    end

    shared_examples_for 'specified dashboard embed' do |expected_titles|
      it_behaves_like '200 response'

      it 'contains only the specified charts' do
        get :metrics_dashboard, params: environment_params(dashboard_params)

        dashboard = json_response['dashboard']
        panel_group = dashboard['panel_groups'].first
        titles = panel_group['panels'].map { |panel| panel['title'] }

        expect(dashboard['dashboard']).to be_nil
        expect(dashboard['panel_groups'].length).to eq 1
        expect(panel_group['group']).to be_nil
        expect(titles).to eq expected_titles
      end
    end

    shared_examples_for 'the default dynamic dashboard' do
      it_behaves_like 'specified dashboard embed', ['Memory Usage (Total)', 'Core Usage (Total)']
    end

    shared_examples_for 'dashboard can be specified' do
      context 'when dashboard is specified' do
        let(:dashboard_path) { '.gitlab/dashboards/test.yml' }
        let(:dashboard_params) { { format: :json, dashboard: dashboard_path } }

        it_behaves_like 'error response', :not_found

        context 'when the project dashboard is available' do
          let(:dashboard_yml) { fixture_file('lib/gitlab/metrics/dashboard/sample_dashboard.yml') }
          let(:project) { project_with_dashboard(dashboard_path, dashboard_yml) }
          let(:environment) { create(:environment, name: 'production', project: project) }

          before do
            project.add_maintainer(user)
          end

          it_behaves_like 'the specified dashboard', 'Test Dashboard'
        end

        context 'when the specified dashboard is the default dashboard' do
          let(:dashboard_path) { system_dashboard_path }

          it_behaves_like 'the default dashboard'
        end
      end
    end

    shared_examples_for 'dashboard can be embedded' do
      context 'when the embedded flag is included' do
        let(:dashboard_params) { { format: :json, embedded: true } }

        it_behaves_like 'the default dynamic dashboard'

        context 'when incomplete dashboard params are provided' do
          let(:dashboard_params) { { format: :json, embedded: true, title: 'Title' } }

          # The title param should be ignored.
          it_behaves_like 'the default dynamic dashboard'
        end

        context 'when invalid params are provided' do
          let(:dashboard_params) { { format: :json, embedded: true, metric_id: 16 } }

          # The superfluous param should be ignored.
          it_behaves_like 'the default dynamic dashboard'
        end

        context 'when the dashboard is correctly specified' do
          let(:dashboard_params) do
            {
              format: :json,
              embedded: true,
              dashboard: system_dashboard_path,
              group: business_metric_title,
              title: 'title',
              y_label: 'y_label'
            }
          end

          it_behaves_like 'error response', :not_found

          context 'and exists' do
            let!(:metric) { create(:prometheus_metric, project: project) }

            it_behaves_like 'specified dashboard embed', ['title']
          end
        end
      end
    end

    shared_examples_for 'dashboard cannot be specified' do
      context 'when dashboard is specified' do
        let(:dashboard_params) { { format: :json, dashboard: '.gitlab/dashboards/test.yml' } }

        it_behaves_like 'the default dashboard'
      end
    end

    let(:dashboard_params) { { format: :json } }

    it_behaves_like 'the default dashboard'
    it_behaves_like 'dashboard can be specified'
    it_behaves_like 'dashboard can be embedded'

    context 'with anonymous user and public dashboard visibility' do
      let(:project) { create(:project, :public) }
      let(:user) { create(:user) }

      before do
        project.project_feature.update!(metrics_dashboard_access_level: ProjectFeature::ENABLED)
      end

      it_behaves_like 'the default dashboard'
    end

    context 'permissions' do
      before do
        allow(controller).to receive(:can?).and_return true
      end

      it 'checks :metrics_dashboard ability' do
        expect(controller).to receive(:can?).with(anything, :metrics_dashboard, anything)

        get :metrics, params: environment_params
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
    opts.reverse_merge(namespace_id: project.namespace,
                       project_id: project,
                       id: environment.id)
  end

  def additional_metrics(opts = {})
    get :additional_metrics, params: environment_params(format: :json, **opts)
  end
end

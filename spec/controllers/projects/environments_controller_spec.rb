require 'spec_helper'

describe Projects::EnvironmentsController do
  set(:user) { create(:user) }
  set(:project) { create(:project) }

  set(:environment) do
    create(:environment, name: 'production', project: project)
  end

  before do
    project.add_master(user)

    sign_in(user)
  end

  describe 'GET index' do
    context 'when a request for the HTML is made' do
      it 'responds with status code 200' do
        get :index, environment_params

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when requesting JSON response for folders' do
      before do
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

      context 'when requesting available environments scope' do
        before do
          get :index, environment_params(format: :json, scope: :available)
        end

        it 'responds with a payload describing available environments' do
          expect(environments.count).to eq 2
          expect(environments.first['name']).to eq 'production'
          expect(environments.second['name']).to eq 'staging'
          expect(environments.second['size']).to eq 2
          expect(environments.second['latest']['name']).to eq 'staging/review-2'
        end

        it 'contains values describing environment scopes sizes' do
          expect(json_response['available_count']).to eq 3
          expect(json_response['stopped_count']).to eq 1
        end

        it 'sets the polling interval header' do
          expect(response).to have_gitlab_http_status(:ok)
          expect(response.headers['Poll-Interval']).to eq("3000")
        end
      end

      context 'when requesting stopped environments scope' do
        before do
          get :index, environment_params(format: :json, scope: :stopped)
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
        get :folder, namespace_id: project.namespace,
                     project_id: project,
                     id: 'staging-1.0'

        expect(response).to be_ok
        expect(response).to render_template 'folder'
      end
    end

    context 'when using JSON format' do
      it 'sorts the subfolders lexicographically' do
        get :folder, namespace_id: project.namespace,
                     project_id: project,
                     id: 'staging-1.0',
                     format: :json

        expect(response).to be_ok
        expect(response).not_to render_template 'folder'
        expect(json_response['environments'][0])
          .to include('name' => 'staging-1.0/review')
        expect(json_response['environments'][1])
          .to include('name' => 'staging-1.0/zzz')
      end
    end
  end

  describe 'GET show' do
    context 'with valid id' do
      it 'responds with a status code 200' do
        get :show, environment_params

        expect(response).to be_ok
      end
    end

    context 'with invalid id' do
      it 'responds with a status code 404' do
        params = environment_params
        params[:id] = 12345
        get :show, params

        expect(response).to have_gitlab_http_status(404)
      end
    end
  end

  describe 'GET edit' do
    it 'responds with a status code 200' do
      get :edit, environment_params

      expect(response).to be_ok
    end
  end

  describe 'PATCH #update' do
    it 'responds with a 302' do
      patch_params = environment_params.merge(environment: { external_url: 'https://git.gitlab.com' })
      patch :update, patch_params

      expect(response).to have_gitlab_http_status(302)
    end
  end

  describe 'PATCH #stop' do
    context 'when env not available' do
      it 'returns 404' do
        allow_any_instance_of(Environment).to receive(:available?) { false }

        patch :stop, environment_params(format: :json)

        expect(response).to have_gitlab_http_status(404)
      end
    end

    context 'when stop action' do
      it 'returns action url' do
        action = create(:ci_build, :manual)

        allow_any_instance_of(Environment)
          .to receive_messages(available?: true, stop_with_action!: action)

        patch :stop, environment_params(format: :json)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to eq(
          { 'redirect_url' =>
              project_job_url(project, action) })
      end
    end

    context 'when no stop action' do
      it 'returns env url' do
        allow_any_instance_of(Environment)
          .to receive_messages(available?: true, stop_with_action!: nil)

        patch :stop, environment_params(format: :json)

        expect(response).to have_gitlab_http_status(200)
        expect(json_response).to eq(
          { 'redirect_url' =>
              project_environment_url(project, environment) })
      end
    end
  end

  describe 'GET #terminal' do
    context 'with valid id' do
      it 'responds with a status code 200' do
        get :terminal, environment_params

        expect(response).to have_gitlab_http_status(200)
      end

      it 'loads the terminals for the enviroment' do
        expect_any_instance_of(Environment).to receive(:terminals)

        get :terminal, environment_params
      end
    end

    context 'with invalid id' do
      it 'responds with a status code 404' do
        get :terminal, environment_params(id: 666)

        expect(response).to have_gitlab_http_status(404)
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
          expect_any_instance_of(Environment)
            .to receive(:terminals)
            .and_return([:fake_terminal])

          expect(Gitlab::Workhorse)
            .to receive(:terminal_websocket)
            .with(:fake_terminal)
            .and_return(workhorse: :response)

          get :terminal_websocket_authorize, environment_params

          expect(response).to have_gitlab_http_status(200)
          expect(response.headers["Content-Type"]).to eq(Gitlab::Workhorse::INTERNAL_API_CONTENT_TYPE)
          expect(response.body).to eq('{"workhorse":"response"}')
        end
      end

      context 'and invalid id' do
        it 'returns 404' do
          get :terminal_websocket_authorize, environment_params(id: 666)

          expect(response).to have_gitlab_http_status(404)
        end
      end
    end

    context 'with invalid workhorse signature' do
      it 'aborts with an exception' do
        allow(Gitlab::Workhorse).to receive(:verify_api_request!).and_raise(JWT::DecodeError)

        expect { get :terminal_websocket_authorize, environment_params }.to raise_error(JWT::DecodeError)
        # controller tests don't set the response status correctly. It's enough
        # to check that the action raised an exception
      end
    end
  end

  describe 'GET #metrics' do
    before do
      allow(controller).to receive(:environment).and_return(environment)
    end

    context 'when environment has no metrics' do
      before do
        expect(environment).to receive(:metrics).and_return(nil)
      end

      it 'returns a metrics page' do
        get :metrics, environment_params

        expect(response).to be_ok
      end

      context 'when requesting metrics as JSON' do
        it 'returns a metrics JSON document' do
          get :metrics, environment_params(format: :json)

          expect(response).to have_gitlab_http_status(204)
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
        get :metrics, environment_params(format: :json)

        expect(response).to be_ok
        expect(json_response['success']).to be(true)
        expect(json_response['metrics']).to eq({})
        expect(json_response['last_update']).to eq(42)
      end
    end
  end

  describe 'GET #additional_metrics' do
    before do
      allow(controller).to receive(:environment).and_return(environment)
    end

    context 'when environment has no metrics' do
      before do
        expect(environment).to receive(:additional_metrics).and_return(nil)
      end

      context 'when requesting metrics as JSON' do
        it 'returns a metrics JSON document' do
          get :additional_metrics, environment_params(format: :json)

          expect(response).to have_gitlab_http_status(204)
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
        get :additional_metrics, environment_params(format: :json)

        expect(response).to be_ok
        expect(json_response['success']).to be(true)
        expect(json_response['data']).to eq({})
        expect(json_response['last_update']).to eq(42)
      end
    end
  end

  def environment_params(opts = {})
    opts.reverse_merge(namespace_id: project.namespace,
                       project_id: project,
                       id: environment.id)
  end
end

require 'spec_helper'

describe Projects::EnvironmentsController do
  include KubernetesHelpers

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

      context 'when requesting available environments scope' do
        before do
          stub_licensed_features(deploy_board: true)

          get :index, environment_params(format: :json, scope: :available)
        end

        it 'responds with matching schema' do
          expect(response).to match_response_schema('environments', dir: 'ee')
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
      end

      context 'when license does not has the GitLab_DeployBoard add-on' do
        before do
          stub_licensed_features(deploy_board: false)

          get :index, environment_params(format: :json)
        end

        it 'does not return the rollout_status_path attribute' do
          expect(environments.first['latest']['rollout_status']).not_to be_present
          expect(environments.second['latest']['rollout_status']).not_to be_present
        end
      end
    end
  end

  describe 'GET logs' do
    let(:logs) { "Log 1\nLog 2\nLog 3" }
    let(:pod_name) { 'foo' }

    before do
      stub_licensed_features(pod_logs: true)

      create(:cluster, :provided_by_gcp,
             environment_scope: '*', projects: [project])

      allow_any_instance_of(EE::KubernetesService).to receive(:read_pod_logs).with(pod_name).and_return(logs)
    end

    context 'when unlicensed' do
      before do
        stub_licensed_features(pod_logs: false)
      end

      it 'renders forbidden' do
        get :logs, environment_params(pod_name: pod_name)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when using HTML format' do
      it 'renders logs template' do
        get :logs, environment_params(pod_name: pod_name)

        expect(response).to be_ok
        expect(response).to render_template 'logs'
      end
    end

    context 'when using JSON format' do
      it 'returns the logs for a specific pod' do
        get :logs, environment_params(pod_name: pod_name, format: :json)

        expect(response).to be_ok
        expect(json_response["logs"]).to match_array(["Log 1", "Log 2", "Log 3"])
      end
    end
  end

  def environment_params(opts = {})
    opts.reverse_merge(namespace_id: project.namespace,
                       project_id: project,
                       id: environment.id)
  end
end

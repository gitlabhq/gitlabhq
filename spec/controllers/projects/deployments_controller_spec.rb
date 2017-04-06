require 'spec_helper'

describe Projects::DeploymentsController do
  include ApiHelpers

  let(:user) { create(:user) }
  let(:project) { create(:empty_project) }
  let(:environment) { create(:environment, name: 'production', project: project) }
  let(:deployment) { create(:deployment, project: project, environment: environment) }

  before do
    project.team << [user, :master]

    sign_in(user)
  end

  describe 'GET #metrics' do
    before do
      allow(controller).to receive(:deployment).and_return(deployment)
    end

    context 'when environment has no metrics' do
      before do
        expect(deployment).to receive(:metrics).and_return(nil)
      end

      it 'returns a empty response 204 resposne' do
        get :metrics, deployment_params
        expect(response).to have_http_status(204)
        expect(response.body).to eq('')
      end
    end

    context 'when environment has some metrics' do
      let(:empty_metrics) do
        {
          success: true,
          metrics: {},
          last_update: 42
        }
      end

      before do
        expect(deployment).to receive(:metrics).and_return(empty_metrics)
      end

      it 'returns a metrics JSON document' do
        get :metrics, deployment_params

        expect(response).to be_ok
        expect(json_response['success']).to be(true)
        expect(json_response['metrics']).to eq({})
        expect(json_response['last_update']).to eq(42)
      end
    end
  end

  def deployment_params(opts = {})
    opts.reverse_merge(namespace_id: project.namespace,
                       project_id: project,
                       environment_id: environment.id,
                       id: deployment.id)
  end
end

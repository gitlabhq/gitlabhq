require 'spec_helper'

describe Projects::EnvironmentScalingsController do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:environment) { create(:environment, project: project) }

  before do
    project.add_master(user)

    sign_in(user)
  end

  describe 'GET show' do
    subject { get :show, namespace_id: project.namespace.to_param, project_id: project, environment_id: environment, format: :json }

    context 'when scaling is available' do
      before do
        allow_any_instance_of(EnvironmentScaling).to receive(:available?).and_return(true)
      end

      it 'respons with ok status code' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'when scaling is not available' do
      before do
        allow_any_instance_of(EnvironmentScaling).to receive(:available?).and_return(false)
      end

      it 'respons with bad_request status code' do
        subject

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end
  end

  describe 'POST update' do
    subject { post :update, namespace_id: project.namespace.to_param, project_id: project, environment_id: environment, environment_scaling: scaling_params, format: :json }

    before do
      environment.create_scaling(production_replicas: 1)
    end

    context 'with valid parameters' do
      let(:scaling_params) { { production_replicas: '5' } }

      it 'responds with ok status code' do
        subject

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'updates the scaling options' do
        expect { subject }.to change { environment.reload.scaling.production_replicas }.to(5)
      end
    end

    context 'with an invalid parameter' do
      let(:scaling_params) { { production_replicas: 'hello' } }

      it 'responds with bad_request status code' do
        subject

        expect(response).to have_gitlab_http_status(:bad_request)
      end

      it 'does not update the scaling options' do
        expect { subject }.not_to change { environment.reload.scaling.production_replicas }
      end
    end
  end
end

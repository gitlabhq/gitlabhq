# frozen_string_literal: true

require 'spec_helper'

describe Projects::DeploymentsController do
  include ApiHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:environment) { create(:environment, name: 'production', project: project) }

  before do
    project.add_maintainer(user)

    sign_in(user)
  end

  describe 'GET #index' do
    it 'returns list of deployments from last 8 hours' do
      create(:deployment, :success, environment: environment, created_at: 9.hours.ago)
      create(:deployment, :success, environment: environment, created_at: 7.hours.ago)
      create(:deployment, :success, environment: environment)

      get :index, params: deployment_params(after: 8.hours.ago)

      expect(response).to be_ok

      expect(json_response['deployments'].count).to eq(2)
    end

    it 'returns a list with deployments information' do
      create(:deployment, :success, environment: environment)

      get :index, params: deployment_params

      expect(response).to be_ok
      expect(response).to match_response_schema('deployments')
    end
  end

  describe 'GET #metrics' do
    let(:deployment) { create(:deployment, :success, project: project, environment: environment) }

    context 'when metrics are disabled' do
      it 'responds with not found' do
        get :metrics, params: deployment_params(id: deployment.to_param)

        expect(response).to be_not_found
      end
    end

    context 'when metrics are enabled' do
      context 'when environment has no metrics' do
        before do
          expect_next_instance_of(DeploymentMetrics) do |deployment_metrics|
            allow(deployment_metrics).to receive(:has_metrics?).and_return(true)

            expect(deployment_metrics).to receive(:metrics).and_return(nil)
          end
        end

        it 'returns a empty response 204 resposne' do
          get :metrics, params: deployment_params(id: deployment.to_param)
          expect(response).to have_gitlab_http_status(204)
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

        it 'returns a metrics JSON document' do
          expect_next_instance_of(DeploymentMetrics) do |deployment_metrics|
            allow(deployment_metrics).to receive(:has_metrics?).and_return(true)

            expect(deployment_metrics).to receive(:metrics).and_return(empty_metrics)
          end

          get :metrics, params: deployment_params(id: deployment.to_param)

          expect(response).to be_ok
          expect(json_response['success']).to be(true)
          expect(json_response['metrics']).to eq({})
          expect(json_response['last_update']).to eq(42)
        end

        it 'returns a 404 if the deployment failed' do
          failed_deployment = create(
            :deployment,
            :failed,
            project: project,
            environment: environment
          )

          get :metrics, params: deployment_params(id: failed_deployment.to_param)

          expect(response).to have_gitlab_http_status(404)
        end
      end
    end
  end

  describe 'GET #additional_metrics' do
    let(:deployment) { create(:deployment, :success, project: project, environment: environment) }

    context 'when metrics are disabled' do
      it 'responds with not found' do
        get :metrics, params: deployment_params(id: deployment.to_param)

        expect(response).to be_not_found
      end
    end

    context 'when metrics are enabled' do
      context 'when environment has no metrics' do
        before do
          expect_next_instance_of(DeploymentMetrics) do |deployment_metrics|
            allow(deployment_metrics).to receive(:has_metrics?).and_return(true)

            expect(deployment_metrics).to receive(:additional_metrics).and_return({})
          end
        end

        it 'returns a empty response 204 response' do
          get :additional_metrics, params: deployment_params(id: deployment.to_param, format: :json)
          expect(response).to have_gitlab_http_status(204)
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
          expect_next_instance_of(DeploymentMetrics) do |deployment_metrics|
            allow(deployment_metrics).to receive(:has_metrics?).and_return(true)

            expect(deployment_metrics).to receive(:additional_metrics).and_return(empty_metrics)
          end
        end

        it 'returns a metrics JSON document' do
          get :additional_metrics, params: deployment_params(id: deployment.to_param, format: :json)

          expect(response).to be_ok
          expect(json_response['success']).to be(true)
          expect(json_response['metrics']).to eq({})
          expect(json_response['last_update']).to eq(42)
        end
      end
    end
  end

  def deployment_params(opts = {})
    opts.reverse_merge(namespace_id: project.namespace,
                       project_id: project,
                       environment_id: environment.id)
  end
end

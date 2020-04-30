# frozen_string_literal: true

require 'spec_helper'

describe Projects::LogsController do
  include KubernetesHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  let_it_be(:environment) do
    create(:environment, name: 'production', project: project)
  end

  let(:pod_name) { "foo" }
  let(:container) { 'container-1' }

  before do
    project.add_maintainer(user)

    sign_in(user)
  end

  describe 'GET #index' do
    let(:empty_project) { create(:project) }

    it 'renders empty logs page if no environment exists' do
      empty_project.add_maintainer(user)
      get :index, params: { namespace_id: empty_project.namespace, project_id: empty_project }

      expect(response).to be_ok
      expect(response).to render_template 'empty_logs'
    end

    it 'renders index template' do
      get :index, params: environment_params

      expect(response).to be_ok
      expect(response).to render_template 'index'
    end
  end

  shared_examples 'pod logs service' do |endpoint, service|
    let(:service_result) do
      {
        status: :success,
        logs: ['Log 1', 'Log 2', 'Log 3'],
        pods: [pod_name],
        pod_name: pod_name,
        container_name: container
      }
    end
    let(:service_result_json) { Gitlab::Json.parse(service_result.to_json) }

    let_it_be(:cluster) { create(:cluster, :provided_by_gcp, environment_scope: '*', projects: [project]) }

    before do
      allow_next_instance_of(service) do |instance|
        allow(instance).to receive(:execute).and_return(service_result)
      end
    end

    it 'returns the service result' do
      get endpoint, params: environment_params(pod_name: pod_name, format: :json)

      expect(response).to have_gitlab_http_status(:success)
      expect(json_response).to eq(service_result_json)
    end

    it 'registers a usage of the endpoint' do
      expect(::Gitlab::UsageCounters::PodLogs).to receive(:increment).with(project.id)

      get endpoint, params: environment_params(pod_name: pod_name, format: :json)

      expect(response).to have_gitlab_http_status(:success)
    end

    it 'sets the polling header' do
      get endpoint, params: environment_params(pod_name: pod_name, format: :json)

      expect(response).to have_gitlab_http_status(:success)
      expect(response.headers['Poll-Interval']).to eq('3000')
    end

    context 'when service is processing' do
      let(:service_result) { nil }

      it 'returns a 202' do
        get endpoint, params: environment_params(pod_name: pod_name, format: :json)

        expect(response).to have_gitlab_http_status(:accepted)
      end
    end

    shared_examples 'unsuccessful execution response' do |message|
      let(:service_result) do
        {
          status: :error,
          message: message
        }
      end

      it 'returns the error' do
        get endpoint, params: environment_params(pod_name: pod_name, format: :json)

        expect(response).to have_gitlab_http_status(:bad_request)
        expect(json_response).to eq(service_result_json)
      end
    end

    context 'when service is failing' do
      it_behaves_like 'unsuccessful execution response', 'some error'
    end

    context 'when cluster is nil' do
      let!(:cluster) { nil }

      it_behaves_like 'unsuccessful execution response', 'Environment does not have deployments'
    end

    context 'when namespace is empty' do
      before do
        allow(environment).to receive(:deployment_namespace).and_return('')
      end

      it_behaves_like 'unsuccessful execution response', 'Environment does not have deployments'
    end
  end

  describe 'GET #k8s' do
    it_behaves_like 'pod logs service', :k8s, PodLogs::KubernetesService
  end

  describe 'GET #elasticsearch' do
    it_behaves_like 'pod logs service', :elasticsearch, PodLogs::ElasticsearchService
  end

  def environment_params(opts = {})
    opts.reverse_merge(namespace_id: project.namespace,
                       project_id: project,
                       environment_name: environment.name)
  end
end

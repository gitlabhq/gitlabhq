# frozen_string_literal: true

require 'spec_helper'

describe Projects::Serverless::FunctionsFinder do
  include KubernetesHelpers
  include PrometheusHelpers
  include ReactiveCachingHelpers

  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:cluster) { create(:cluster, :project, :provided_by_gcp, projects: [project]) }
  let(:service) { cluster.platform_kubernetes }
  let(:environment) { create(:environment, project: project) }
  let!(:deployment) { create(:deployment, :success, environment: environment, cluster: cluster) }
  let(:knative_services_finder) { environment.knative_services_finder }

  let(:namespace) do
    create(:cluster_kubernetes_namespace,
      cluster: cluster,
      project: project,
      environment: environment)
  end

  before do
    project.add_maintainer(user)
  end

  describe '#installed' do
    it 'when reactive_caching is still fetching data' do
      expect(described_class.new(project).knative_installed).to eq 'checking'
    end

    context 'when reactive_caching has finished' do
      before do
        allow(Clusters::KnativeServicesFinder)
          .to receive(:new)
          .and_return(knative_services_finder)
        synchronous_reactive_cache(knative_services_finder)
      end

      context 'when knative is not installed' do
        it 'returns false' do
          stub_kubeclient_discover_knative_not_found(service.api_url)

          expect(described_class.new(project).knative_installed).to eq false
        end
      end

      context 'reactive_caching is finished and knative is installed' do
        it 'returns true' do
          stub_kubeclient_knative_services(namespace: namespace.namespace)
          stub_kubeclient_service_pods(nil, namespace: namespace.namespace)

          expect(described_class.new(project).knative_installed).to be true
        end
      end
    end
  end

  describe 'retrieve data from knative' do
    context 'does not have knative installed' do
      it { expect(described_class.new(project).execute).to be_empty }
    end

    context 'has knative installed' do
      let!(:knative) { create(:clusters_applications_knative, :installed, cluster: cluster) }
      let(:finder) { described_class.new(project) }

      it 'there are no functions' do
        expect(finder.execute).to be_empty
      end

      it 'there are functions', :use_clean_rails_memory_store_caching do
        stub_kubeclient_service_pods
        stub_reactive_cache(knative_services_finder,
          {
            services: kube_knative_services_body(namespace: namespace.namespace, name: cluster.project.name)["items"],
            pods: kube_knative_pods_body(cluster.project.name, namespace.namespace)["items"]
          },
          *knative_services_finder.cache_args)

        expect(finder.execute).not_to be_empty
      end

      it 'has a function', :use_clean_rails_memory_store_caching do
        stub_kubeclient_service_pods
        stub_reactive_cache(knative_services_finder,
          {
            services: kube_knative_services_body(namespace: namespace.namespace, name: cluster.project.name)["items"],
            pods: kube_knative_pods_body(cluster.project.name, namespace.namespace)["items"]
          },
          *knative_services_finder.cache_args)

        result = finder.service(cluster.environment_scope, cluster.project.name)
        expect(result).not_to be_empty
        expect(result["metadata"]["name"]).to be_eql(cluster.project.name)
      end

      it 'has metrics', :use_clean_rails_memory_store_caching do
      end
    end

    context 'has prometheus' do
      let(:prometheus_adapter) { double('prometheus_adapter', can_query?: true) }
      let!(:knative) { create(:clusters_applications_knative, :installed, cluster: cluster) }
      let!(:prometheus) { create(:clusters_applications_prometheus, :installed, cluster: cluster) }
      let(:finder) { described_class.new(project) }

      before do
        allow(Prometheus::AdapterService).to receive(:new).and_return(double(prometheus_adapter: prometheus_adapter))
        allow(prometheus_adapter).to receive(:query).and_return(prometheus_empty_body('matrix'))
      end

      it 'is available' do
        expect(finder.has_prometheus?("*")).to be true
      end

      it 'has query data' do
        expect(finder.invocation_metrics("*", cluster.project.name)).not_to be_nil
      end
    end
  end
end

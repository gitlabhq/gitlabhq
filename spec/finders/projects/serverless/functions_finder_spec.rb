# frozen_string_literal: true

require 'spec_helper'

describe Projects::Serverless::FunctionsFinder do
  include KubernetesHelpers
  include PrometheusHelpers
  include ReactiveCachingHelpers

  let(:user) { create(:user) }
  let(:cluster) { create(:cluster, :project, :provided_by_gcp) }
  let(:service) { cluster.platform_kubernetes }
  let(:project) { cluster.project}

  let(:namespace) do
    create(:cluster_kubernetes_namespace,
      cluster: cluster,
      cluster_project: cluster.cluster_project,
      project: cluster.cluster_project.project)
  end

  before do
    project.add_maintainer(user)
  end

  describe 'retrieve data from knative' do
    it 'does not have knative installed' do
      expect(described_class.new(project).execute).to be_empty
    end

    context 'has knative installed' do
      let!(:knative) { create(:clusters_applications_knative, :installed, cluster: cluster) }
      let(:finder) { described_class.new(project) }

      it 'there are no functions' do
        expect(finder.execute).to be_empty
      end

      it 'there are functions', :use_clean_rails_memory_store_caching do
        stub_kubeclient_service_pods
        stub_reactive_cache(knative,
          {
            services: kube_knative_services_body(namespace: namespace.namespace, name: cluster.project.name)["items"],
            pods: kube_knative_pods_body(cluster.project.name, namespace.namespace)["items"]
          })

        expect(finder.execute).not_to be_empty
      end

      it 'has a function', :use_clean_rails_memory_store_caching do
        stub_kubeclient_service_pods
        stub_reactive_cache(knative,
          {
            services: kube_knative_services_body(namespace: namespace.namespace, name: cluster.project.name)["items"],
            pods: kube_knative_pods_body(cluster.project.name, namespace.namespace)["items"]
          })

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
        allow(finder).to receive(:prometheus_adapter).and_return(prometheus_adapter)
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

  describe 'verify if knative is installed' do
    context 'knative is not installed' do
      it 'does not have knative installed' do
        expect(described_class.new(project).installed?).to be false
      end
    end

    context 'knative is installed' do
      let!(:knative) { create(:clusters_applications_knative, :installed, cluster: cluster) }

      it 'does have knative installed' do
        expect(described_class.new(project).installed?).to be true
      end
    end
  end
end

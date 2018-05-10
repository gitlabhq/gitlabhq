require 'spec_helper'

describe Clusters::Platforms::Kubernetes, :use_clean_rails_memory_store_caching do
  include KubernetesHelpers
  include ReactiveCachingHelpers

  describe '#calculate_reactive_cache' do
    subject { service.calculate_reactive_cache }

    let!(:cluster) { create(:cluster, :project, enabled: enabled, platform_kubernetes: service) }
    let(:service) { create(:cluster_platform_kubernetes, :configured) }
    let(:enabled) { true }

    context 'when kubernetes responds with valid pods and deployments' do
      before do
        stub_kubeclient_pods
        stub_kubeclient_deployments
      end

      it { is_expected.to eq(pods: [kube_pod], deployments: [kube_deployment]) }
    end

    context 'when kubernetes responds with 500s' do
      before do
        stub_kubeclient_pods(status: 500)
        stub_kubeclient_deployments(status: 500)
      end

      it { expect { subject }.to raise_error(Kubeclient::HttpError) }
    end

    context 'when kubernetes responds with 404s' do
      before do
        stub_kubeclient_pods(status: 404)
        stub_kubeclient_deployments(status: 404)
      end

      it { is_expected.to eq(pods: [], deployments: []) }
    end
  end
end

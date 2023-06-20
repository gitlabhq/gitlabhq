# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::KnativeServicesFinder do
  include KubernetesHelpers
  include ReactiveCachingHelpers

  let(:project) { create(:project, :repository) }
  let(:cluster) { deployment.cluster }
  let(:service) { environment.deployment_platform }
  let(:environment) { create(:environment, project: project) }
  let!(:deployment) { create(:deployment, :success, :on_cluster, environment: environment) }
  let(:namespace) do
    create(:cluster_kubernetes_namespace,
      cluster: cluster,
      project: project,
      environment: environment)
  end

  let(:finder) { described_class.new(cluster, environment) }

  before do
    stub_kubeclient_knative_services(namespace: namespace.namespace)
    stub_kubeclient_service_pods(
      kube_response(
        kube_knative_pods_body(
          project.name, namespace.namespace
        )
      ),
      namespace: namespace.namespace
    )
  end

  shared_examples 'a cached data' do
    it 'has an unintialized cache' do
      is_expected.to be_blank
    end

    context 'when using synchronous reactive cache' do
      before do
        synchronous_reactive_cache(finder)
      end

      context 'when there are functions for cluster namespace' do
        it { is_expected.not_to be_blank }
      end

      context 'when there are no functions for cluster namespace' do
        before do
          stub_kubeclient_knative_services(
            namespace: namespace.namespace,
            response: kube_response({ "kind" => "ServiceList", "items" => [] })
          )
          stub_kubeclient_service_pods(
            kube_response({ "kind" => "PodList", "items" => [] }),
            namespace: namespace.namespace
          )
        end

        it { is_expected.to be_blank }
      end
    end
  end

  describe '#service_pod_details' do
    subject { finder.service_pod_details(project.name) }

    it_behaves_like 'a cached data'
  end

  describe '#services' do
    subject { finder.services }

    it_behaves_like 'a cached data'
  end

  describe '#knative_detected' do
    subject { finder.knative_detected }

    before do
      synchronous_reactive_cache(finder)
    end

    context 'when knative is installed' do
      before do
        stub_kubeclient_discover(service.api_url)
      end

      it { is_expected.to be_truthy }

      it "discovers knative installation" do
        expect { subject }
          .to change { finder.cluster.kubeclient.knative_client.discovered }
          .from(false)
          .to(true)
      end
    end

    context 'when knative is not installed' do
      before do
        stub_kubeclient_discover_knative_not_found(service.api_url)
      end

      it { is_expected.to be_falsy }

      it "does not discover knative installation" do
        expect { subject }.not_to change { cluster.kubeclient.knative_client.discovered }
      end
    end
  end
end

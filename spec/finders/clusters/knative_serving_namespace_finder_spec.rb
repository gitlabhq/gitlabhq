# frozen_string_literal: true

require 'spec_helper'

describe Clusters::KnativeServingNamespaceFinder do
  include KubernetesHelpers
  let(:cluster) { create(:cluster, :project, :provided_by_gcp) }
  let(:service) { environment.deployment_platform }
  let(:project) { cluster.cluster_project.project }
  let(:environment) { create(:environment, project: project) }

  subject { described_class.new(cluster) }

  before do
    stub_kubeclient_discover(service.api_url)
  end

  it 'finds the namespace in a cluster where it exists' do
    stub_kubeclient_get_namespace(service.api_url, namespace: Clusters::Kubernetes::KNATIVE_SERVING_NAMESPACE)
    expect(subject.execute).to be_a Kubeclient::Resource
  end

  it 'returns nil in a cluster where it does not' do
    stub_kubeclient_get_namespace(
      service.api_url,
        namespace: Clusters::Kubernetes::KNATIVE_SERVING_NAMESPACE,
        response: {
            status: [404, "Resource Not Found"]
        }
    )
    expect(subject.execute).to be nil
  end

  it 'returns nil in a cluster where the lookup results in a 403 as it will in some versions of kubernetes' do
    stub_kubeclient_get_namespace(
      service.api_url,
        namespace: Clusters::Kubernetes::KNATIVE_SERVING_NAMESPACE,
        response: {
            status: [403, "Resource Not Found"]
        }
    )
    expect(subject.execute).to be nil
  end

  it 'raises an error if error code is not 404 or 403' do
    stub_kubeclient_get_namespace(
      service.api_url,
        namespace: Clusters::Kubernetes::KNATIVE_SERVING_NAMESPACE,
        response: {
            status: [500, "Internal Server Error"]
        }
    )
    expect { subject.execute }.to raise_error(Kubeclient::HttpError)
  end
end

require 'spec_helper'

describe KubernetesService, models: true, use_clean_rails_memory_store_caching: true do
  include KubernetesHelpers
  include ReactiveCachingHelpers

  shared_examples 'same behavior between KubernetesService and Platform::Kubernetes' do
    let(:service) { project.deployment_platform }

    describe '#rollout_status' do
      let(:environment) { build(:environment, project: project, name: "env", slug: "env-000000") }

      subject(:rollout_status) { service.rollout_status(environment) }

      context 'with valid deployments' do
        before do
          stub_reactive_cache(
            service,
            deployments: [kube_deployment(app: environment.slug), kube_deployment],
            pods: [kube_pod(app: environment.slug), kube_pod(app: environment.slug, status: 'Pending')]
          )
        end

        it 'creates a matching RolloutStatus' do
          expect(rollout_status).to be_kind_of(::Gitlab::Kubernetes::RolloutStatus)
          expect(rollout_status.deployments.map(&:labels)).to eq([{ 'app' => 'env-000000' }])
        end
      end

      context 'with empty list of deployments' do
        before do
          stub_reactive_cache(
            service,
            deployments: []
          )
        end

        it 'creates a matching RolloutStatus' do
          expect(rollout_status).to be_kind_of(::Gitlab::Kubernetes::RolloutStatus)
          expect(rollout_status).to be_not_found
        end
      end

      context 'not yet loaded deployments' do
        before do
          stub_reactive_cache
        end

        it 'creates a matching RolloutStatus' do
          expect(rollout_status).to be_kind_of(::Gitlab::Kubernetes::RolloutStatus)
          expect(rollout_status).to be_loading
        end
      end
    end
  end

  context 'when user configured kubernetes from Integration > Kubernetes' do
    let(:project) { create(:kubernetes_project) }

    it_behaves_like 'same behavior between KubernetesService and Platform::Kubernetes'
  end

  context 'when user configured kubernetes from CI/CD > Clusters' do
    let!(:cluster) { create(:cluster, :project, :provided_by_gcp) }
    let(:project) { cluster.project }

    it_behaves_like 'same behavior between KubernetesService and Platform::Kubernetes'
  end
end

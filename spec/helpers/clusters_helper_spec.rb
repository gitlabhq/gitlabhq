# frozen_string_literal: true

require 'spec_helper'

describe ClustersHelper do
  describe '#has_rbac_enabled?' do
    context 'when kubernetes platform has been created' do
      let(:platform_kubernetes) { build_stubbed(:cluster_platform_kubernetes) }
      let(:cluster) { build_stubbed(:cluster, :provided_by_gcp, platform_kubernetes: platform_kubernetes) }

      it 'returns kubernetes platform value' do
        expect(helper.has_rbac_enabled?(cluster)).to be_truthy
      end
    end

    context 'when kubernetes platform has not been created yet' do
      let(:cluster) { build_stubbed(:cluster, :providing_by_gcp) }

      it 'delegates to cluster provider' do
        expect(helper.has_rbac_enabled?(cluster)).to be_truthy
      end

      context 'when ABAC cluster is created' do
        let(:provider) { build_stubbed(:cluster_provider_gcp, :abac_enabled) }
        let(:cluster) { build_stubbed(:cluster, :providing_by_gcp, provider_gcp: provider) }

        it 'delegates to cluster provider' do
          expect(helper.has_rbac_enabled?(cluster)).to be_falsy
        end
      end
    end
  end

  describe '#create_new_cluster_label' do
    subject { helper.create_new_cluster_label(provider: provider) }

    context 'GCP provider' do
      let(:provider) { 'gcp' }

      it { is_expected.to eq('Create new Cluster on GKE') }
    end

    context 'AWS provider' do
      let(:provider) { 'aws' }

      it { is_expected.to eq('Create new Cluster on EKS') }
    end

    context 'other provider' do
      let(:provider) { 'other' }

      it { is_expected.to eq('Create new Cluster') }
    end

    context 'no provider' do
      let(:provider) { nil }

      it { is_expected.to eq('Create new Cluster') }
    end
  end

  describe '#render_new_provider_form' do
    subject { helper.new_cluster_partial(provider: provider) }

    context 'GCP provider' do
      let(:provider) { 'gcp' }

      it { is_expected.to eq('clusters/clusters/gcp/new') }
    end

    context 'AWS provider' do
      let(:provider) { 'aws' }

      it { is_expected.to eq('clusters/clusters/aws/new') }
    end

    context 'other provider' do
      let(:provider) { 'other' }

      it { is_expected.to eq('clusters/clusters/cloud_providers/cloud_provider_selector') }
    end

    context 'no provider' do
      let(:provider) { nil }

      it { is_expected.to eq('clusters/clusters/cloud_providers/cloud_provider_selector') }
    end
  end
end

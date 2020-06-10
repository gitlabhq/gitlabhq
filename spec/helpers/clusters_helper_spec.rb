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

      it { is_expected.to eq('Create new cluster on GKE') }
    end

    context 'AWS provider' do
      let(:provider) { 'aws' }

      it { is_expected.to eq('Create new cluster on EKS') }
    end

    context 'other provider' do
      let(:provider) { 'other' }

      it { is_expected.to eq('Create new cluster') }
    end

    context 'no provider' do
      let(:provider) { nil }

      it { is_expected.to eq('Create new cluster') }
    end
  end

  describe '#js_clusters_list_data' do
    it 'displays endpoint path and images' do
      js_data = helper.js_clusters_list_data('/path')

      expect(js_data[:endpoint]).to eq('/path')

      expect(js_data.dig(:img_tags, :aws, :path)).to match(%r(/illustrations/logos/amazon_eks|svg))
      expect(js_data.dig(:img_tags, :default, :path)).to match(%r(/illustrations/logos/kubernetes|svg))
      expect(js_data.dig(:img_tags, :gcp, :path)).to match(%r(/illustrations/logos/google_gke|svg))

      expect(js_data.dig(:img_tags, :aws, :text)).to eq('Amazon EKS')
      expect(js_data.dig(:img_tags, :default, :text)).to eq('Kubernetes Cluster')
      expect(js_data.dig(:img_tags, :gcp, :text)).to eq('Google GKE')
    end
  end

  describe '#provider_icon' do
    it 'will return GCP logo with gcp argument' do
      logo = helper.provider_icon('gcp')

      expect(logo).to match(%r(img alt="Google GKE" data-src="|/illustrations/logos/google_gke|svg))
    end

    it 'will return AWS logo with aws argument' do
      logo = helper.provider_icon('aws')

      expect(logo).to match(%r(img alt="Amazon EKS" data-src="|/illustrations/logos/amazon_eks|svg))
    end

    it 'will return default logo with unknown provider' do
      logo = helper.provider_icon('unknown')

      expect(logo).to match(%r(img alt="Kubernetes Cluster" data-src="|/illustrations/logos/kubernetes|svg))
    end

    it 'will return default logo when provider is empty' do
      logo = helper.provider_icon

      expect(logo).to match(%r(img alt="Kubernetes Cluster" data-src="|/illustrations/logos/kubernetes|svg))
    end
  end

  describe '#cluster_type_label' do
    subject { helper.cluster_type_label(cluster_type) }

    context 'project cluster' do
      let(:cluster_type) { 'project_type' }

      it { is_expected.to eq('Project cluster') }
    end

    context 'group cluster' do
      let(:cluster_type) { 'group_type' }

      it { is_expected.to eq('Group cluster') }
    end

    context 'instance cluster' do
      let(:cluster_type) { 'instance_type' }

      it { is_expected.to eq('Instance cluster') }
    end

    context 'other values' do
      let(:cluster_type) { 'not_supported' }

      it 'Diplays generic cluster and reports error' do
        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).with(
          an_instance_of(ArgumentError),
          cluster_error: { error: 'Cluster Type Missing', cluster_type: 'not_supported' }
        )

        is_expected.to eq('Cluster')
      end
    end
  end
end

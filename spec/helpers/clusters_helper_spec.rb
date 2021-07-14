# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClustersHelper do
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

  describe '#js_cluster_agents_list_data' do
    let_it_be(:project) { build(:project, :repository) }

    subject { helper.js_cluster_agents_list_data(project) }

    it 'displays project default branch' do
      expect(subject[:default_branch_name]).to eq(project.default_branch)
    end

    it 'displays image path' do
      expect(subject[:empty_state_image]).to match(%r(/illustrations/logos/clusters_empty|svg))
    end

    it 'displays project path' do
      expect(subject[:project_path]).to eq(project.full_path)
    end

    it 'generates docs urls' do
      expect(subject[:agent_docs_url]).to eq(help_page_path('user/clusters/agent/index'))
      expect(subject[:install_docs_url]).to eq(help_page_path('administration/clusters/kas'))
      expect(subject[:get_started_docs_url]).to eq(help_page_path('user/clusters/agent/index', anchor: 'define-a-configuration-repository'))
      expect(subject[:integration_docs_url]).to eq(help_page_path('user/clusters/agent/index', anchor: 'get-started-with-gitops-and-the-gitlab-agent'))
    end
  end

  describe '#js_clusters_list_data' do
    subject { helper.js_clusters_list_data('/path') }

    it 'displays endpoint path' do
      expect(subject[:endpoint]).to eq('/path')
    end

    it 'generates svg image data', :aggregate_failures do
      expect(subject.dig(:img_tags, :aws, :path)).to match(%r(/illustrations/logos/amazon_eks|svg))
      expect(subject.dig(:img_tags, :default, :path)).to match(%r(/illustrations/logos/kubernetes|svg))
      expect(subject.dig(:img_tags, :gcp, :path)).to match(%r(/illustrations/logos/google_gke|svg))

      expect(subject.dig(:img_tags, :aws, :text)).to eq('Amazon EKS')
      expect(subject.dig(:img_tags, :default, :text)).to eq('Kubernetes Cluster')
      expect(subject.dig(:img_tags, :gcp, :text)).to eq('Google GKE')
    end

    it 'displays and ancestor_help_path' do
      expect(subject[:ancestor_help_path]).to eq(help_page_path('user/group/clusters/index', anchor: 'cluster-precedence'))
    end
  end

  describe '#js_cluster_new' do
    subject { helper.js_cluster_new }

    it 'displays a cluster_connect_help_path' do
      expect(subject[:cluster_connect_help_path]).to eq(help_page_path('user/project/clusters/add_remove_clusters', anchor: 'add-existing-cluster'))
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

      it 'diplays generic cluster and reports error' do
        expect(Gitlab::ErrorTracking).to receive(:track_and_raise_for_dev_exception).with(
          an_instance_of(ArgumentError),
          cluster_error: { error: 'Cluster Type Missing', cluster_type: 'not_supported' }
        )

        is_expected.to eq('Cluster')
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClustersHelper, feature_category: :deployment_management do
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

  describe '#js_clusters_list_data' do
    let_it_be(:current_user) { create(:user) }
    let_it_be(:project) { build(:project) }
    let_it_be(:clusterable) { ClusterablePresenter.fabricate(project, current_user: current_user) }

    subject { helper.js_clusters_list_data(clusterable) }

    before do
      helper.send(:default_branch_name, clusterable)
      helper.send(:clusterable_project_path, clusterable)
    end

    it 'displays endpoint path' do
      expect(subject[:endpoint]).to eq("#{project_path(project)}/-/clusters.json")
    end

    it 'generates svg image data', :aggregate_failures do
      expect(subject.dig(:img_tags, :aws, :path)).to match(%r{/illustrations/logos/amazon_eks|svg})
      expect(subject.dig(:img_tags, :default, :path)).to match(%r{/illustrations/logos/kubernetes|svg})
      expect(subject.dig(:img_tags, :gcp, :path)).to match(%r{/illustrations/logos/google_gke|svg})

      expect(subject.dig(:img_tags, :aws, :text)).to eq('Amazon EKS')
      expect(subject.dig(:img_tags, :default, :text)).to eq('Kubernetes Cluster')
      expect(subject.dig(:img_tags, :gcp, :text)).to eq('Google GKE')
    end

    it 'displays and ancestor_help_path' do
      expect(subject[:ancestor_help_path]).to eq(help_page_path('user/group/clusters/_index.md', anchor: 'cluster-precedence'))
    end

    it 'displays empty image path' do
      expect(subject[:clusters_empty_state_image]).to match(%r{/illustrations/empty-state/empty-state-clusters|svg})
      expect(subject[:empty_state_image]).to match(%r{/illustrations/empty-state/empty-environment-md|svg})
    end

    it 'displays add cluster using certificate path' do
      expect(subject[:add_cluster_path]).to eq("#{project_path(project)}/-/clusters/connect")
    end

    it 'displays create cluster path' do
      expect(subject[:new_cluster_docs_path]).to eq("#{project_path(project)}/-/clusters/new_cluster_docs")
    end

    it 'displays project default branch' do
      expect(subject[:default_branch_name]).to eq(project.default_branch)
    end

    it 'displays project path' do
      expect(subject[:project_path]).to eq(project.full_path)
    end

    it 'displays kas address' do
      expect(subject[:kas_address]).to eq(Gitlab::Kas.external_url)
    end

    it 'displays KAS versions' do
      expect(subject[:kas_install_version]).to eq(Gitlab::Kas.install_version_info)
      expect(subject[:kas_check_version]).to eq(Gitlab::Kas.display_version_info)
    end

    context 'user has no permissions to create a cluster' do
      it 'displays that user can\'t add cluster' do
        expect(subject[:can_add_cluster]).to eq("false")
        expect(subject[:can_admin_cluster]).to eq("false")
      end
    end

    context 'user is a maintainer' do
      before do
        project.add_maintainer(current_user)
      end

      it 'displays that the user can add cluster' do
        expect(subject[:can_add_cluster]).to eq("true")
        expect(subject[:can_admin_cluster]).to eq("true")
      end
    end

    context 'project cluster' do
      it 'doesn\'t display empty state help text' do
        expect(subject[:empty_state_help_text]).to be_nil
      end

      it 'displays display_cluster_agents as true' do
        expect(subject[:display_cluster_agents]).to eq("true")
      end
    end

    context 'group cluster' do
      let_it_be(:group) { create(:group) }
      let_it_be(:clusterable) { ClusterablePresenter.fabricate(group, current_user: current_user) }

      it 'displays empty state help text' do
        expect(subject[:empty_state_help_text]).to eq(s_('ClusterIntegration|Adding an integration to your group will share the cluster across all your projects.'))
      end

      it 'displays display_cluster_agents as false' do
        expect(subject[:display_cluster_agents]).to eq("false")
      end

      it 'does not include a default branch' do
        expect(subject[:default_branch_name]).to be_nil
      end

      it 'does not include a project path' do
        expect(subject[:project_path]).to be_nil
      end
    end

    describe 'certificate based clusters enabled' do
      before do
        stub_feature_flags(certificate_based_clusters: flag_enabled)
      end

      context 'feature flag is enabled' do
        let(:flag_enabled) { true }

        it do
          expect(subject[:certificate_based_clusters_enabled]).to eq('true')
        end
      end

      context 'feature flag is disabled' do
        let(:flag_enabled) { false }

        it do
          expect(subject[:certificate_based_clusters_enabled]).to eq('false')
        end
      end
    end
  end

  describe '#render_cluster_info_tab_content' do
    subject { helper.render_cluster_info_tab_content(tab, expanded) }

    let(:expanded) { true }

    context 'environments' do
      let(:tab) { 'environments' }

      it 'renders environemtns tab' do
        expect(helper).to receive(:render_if_exists).with('clusters/clusters/environments')
        subject
      end
    end

    context 'health' do
      let(:tab) { 'health' }

      it 'renders details tab' do
        expect(helper).to receive(:render).with('details', { expanded: expanded })
        subject
      end
    end

    context 'apps' do
      let(:tab) { 'apps' }

      it 'renders apps tab' do
        expect(helper).to receive(:render).with('applications')
        subject
      end
    end

    context 'integrations ' do
      let(:tab) { 'integrations' }

      it 'renders details tab' do
        expect(helper).to receive(:render).with('details', { expanded: expanded })
        subject
      end
    end

    context 'settings' do
      let(:tab) { 'settings' }

      it 'renders settings tab' do
        expect(helper).to receive(:render).with('advanced_settings_container')
        subject
      end
    end

    context 'details ' do
      let(:tab) { 'details' }

      it 'renders details tab' do
        expect(helper).to receive(:render).with('details', { expanded: expanded })
        subject
      end
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

  describe '#display_cluster_agents?' do
    subject { helper.display_cluster_agents?(clusterable) }

    context 'when clusterable is a project' do
      let(:clusterable) { build(:project) }

      it 'allows agents to display' do
        expect(subject).to be_truthy
      end
    end

    context 'when clusterable is a group' do
      let(:clusterable) { build(:group) }

      it 'does not allow agents to display' do
        expect(subject).to be_falsey
      end
    end
  end

  describe '#default_branch_name' do
    subject { default_branch_name(clusterable) }

    context 'when clusterable is a project without a repository' do
      let(:clusterable) { build(:project) }

      it 'allows default branch name to display default name from settings' do
        expect(subject).to eq(Gitlab::CurrentSettings.default_branch_name)
      end
    end

    context 'when clusterable is a project with a repository' do
      let(:clusterable) { build(:project, :repository) }
      let(:repository) { clusterable.repository }

      it 'allows default branch name to display repository root branch' do
        expect(subject).to eq(repository.root_ref)
      end
    end

    context 'when clusterable is a group' do
      let(:clusterable) { build(:group) }

      it 'does not allow default branch name to display' do
        expect(subject).to be_nil
      end
    end
  end
end

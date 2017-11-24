require 'spec_helper'

describe ClustersHelper do
  include ApplicationHelper

  describe '.enable_add_cluster_button?' do
    set(:project) { create(:project) }
    set(:user) { create(:user) }
    subject { helper.enable_add_cluster_button?(project) }

    context 'when project does not have a cluster' do
      it { is_expected.to eq(true) }
    end

    context 'when project has a cluster' do
      before do
        params =
        {
          name: 'test-cluster',
          provider_type: :gcp,
          provider_gcp_attributes: {
            gcp_project_id: 'gcp-project',
            zone: 'us-central1-a',
            num_nodes: 1,
            machine_type: 'machine_type-a'
          }
        }
        Clusters::Cluster.create(params.merge(user: user, projects: [project]))
      end

      context 'when project has multiple clusters available' do
        before do
          allow(project).to receive(:feature_available?).with(:multiple_clusters).and_return(true)
        end

        it { is_expected.to eq(true) }
      end

      context 'when project does not have multiple clusters available' do
        before do
          allow(project).to receive(:feature_available?).with(:multiple_clusters).and_return(false)
        end

        it { is_expected.to eq(false) }
      end
    end
  end
end

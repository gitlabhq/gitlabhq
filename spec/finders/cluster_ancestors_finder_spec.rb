# frozen_string_literal: true

require 'spec_helper'

describe ClusterAncestorsFinder, '#execute' do
  let(:group) { create(:group) }
  let(:project) { create(:project, group: group) }
  let(:user) { create(:user) }

  let!(:project_cluster) do
    create(:cluster, :provided_by_user, cluster_type: :project_type, projects: [project])
  end

  let!(:group_cluster) do
    create(:cluster, :provided_by_user, cluster_type: :group_type, groups: [group])
  end

  subject { described_class.new(clusterable, user).execute }

  context 'for a project' do
    let(:clusterable) { project }

    before do
      project.add_maintainer(user)
    end

    it 'returns the project clusters followed by group clusters' do
      is_expected.to eq([project_cluster, group_cluster])
    end

    context 'nested groups', :nested_groups do
      let(:group) { create(:group, parent: parent_group) }
      let(:parent_group) { create(:group) }

      let!(:parent_group_cluster) do
        create(:cluster, :provided_by_user, cluster_type: :group_type, groups: [parent_group])
      end

      it 'returns the project clusters followed by group clusters ordered ascending the hierarchy' do
        is_expected.to eq([project_cluster, group_cluster, parent_group_cluster])
      end
    end
  end

  context 'user cannot read clusters for clusterable' do
    let(:clusterable) { project }

    it 'returns nothing' do
      is_expected.to be_empty
    end
  end

  context 'for a group' do
    let(:clusterable) { group }

    before do
      group.add_maintainer(user)
    end

    it 'returns the list of group clusters' do
      is_expected.to eq([group_cluster])
    end

    context 'nested groups', :nested_groups do
      let(:group) { create(:group, parent: parent_group) }
      let(:parent_group) { create(:group) }

      let!(:parent_group_cluster) do
        create(:cluster, :provided_by_user, cluster_type: :group_type, groups: [parent_group])
      end

      it 'returns the list of group clusters ordered ascending the hierarchy' do
        is_expected.to eq([group_cluster, parent_group_cluster])
      end
    end
  end
end

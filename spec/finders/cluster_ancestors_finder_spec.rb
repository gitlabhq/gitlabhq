# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClusterAncestorsFinder, '#execute' do
  let(:group) { create(:group) }
  let(:project) { create(:project, group: group) }
  let(:user) { create(:user) }

  let!(:project_cluster) do
    create(:cluster, :provided_by_user, :project, projects: [project])
  end

  let!(:group_cluster) do
    create(:cluster, :provided_by_user, :group, groups: [group])
  end

  let!(:instance_cluster) do
    create(:cluster, :provided_by_user, :instance)
  end

  subject { described_class.new(clusterable, user).execute }

  context 'for a project' do
    let(:clusterable) { project }

    before do
      project.add_maintainer(user)
    end

    it 'returns the project clusters followed by group clusters' do
      is_expected.to eq([project_cluster, group_cluster, instance_cluster])
    end

    context 'nested groups' do
      let(:group) { create(:group, parent: parent_group) }
      let(:parent_group) { create(:group) }

      let!(:parent_group_cluster) do
        create(:cluster, :provided_by_user, :group, groups: [parent_group])
      end

      it 'returns the project clusters followed by group clusters ordered ascending the hierarchy' do
        is_expected.to eq([project_cluster, group_cluster, parent_group_cluster, instance_cluster])
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
      is_expected.to eq([group_cluster, instance_cluster])
    end

    context 'nested groups' do
      let(:group) { create(:group, parent: parent_group) }
      let(:parent_group) { create(:group) }

      let!(:parent_group_cluster) do
        create(:cluster, :provided_by_user, :group, groups: [parent_group])
      end

      it 'returns the list of group clusters ordered ascending the hierarchy' do
        is_expected.to eq([group_cluster, parent_group_cluster, instance_cluster])
      end
    end
  end

  context 'for an instance' do
    let(:clusterable) { Clusters::Instance.new }
    let(:user) { create(:admin) }

    context 'when admin mode is enabled', :enable_admin_mode do
      it 'returns the list of instance clusters' do
        is_expected.to eq([instance_cluster])
      end
    end

    context 'when admin mode is disabled' do
      it 'returns nothing' do
        is_expected.to be_empty
      end
    end
  end
end

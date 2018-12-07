# frozen_string_literal: true

require 'spec_helper'

describe ClustersHelper do
  describe '#cluster_group_path_display' do
    subject { helper.cluster_group_path_display(cluster.present, clusterable) }

    context 'for a group cluster' do
      let(:cluster) { create(:cluster, :group) }
      let(:clusterable) { cluster.group }
      let(:cluster_link) { "<a href=\"/groups/#{clusterable.name}/-/clusters/#{cluster.id}\">#{cluster.name}</a>" }

      it 'returns link for cluster' do
        expect(subject).to eq(cluster_link)
      end

      it 'escapes group name' do
        expect(subject).to be_html_safe
      end
    end

    context 'for a project cluster' do
      let(:cluster) { create(:cluster, :project) }
      let(:clusterable) { cluster.project }
      let(:cluster_link) { "<a href=\"/#{clusterable.namespace.name}/#{clusterable.name}/clusters/#{cluster.id}\">#{cluster.name}</a>" }

      it 'returns link for cluster' do
        expect(subject).to eq(cluster_link)
      end

      it 'escapes group name' do
        expect(subject).to be_html_safe
      end
    end

    context 'with subgroups' do
      let(:root_group) { create(:group, name: 'root_group') }
      let(:cluster) { create(:cluster, :group, groups: [root_group]) }
      let(:clusterable) { create(:group, name: 'group', parent: root_group) }

      subject { helper.cluster_group_path_display(cluster.present, clusterable) }

      context 'with just one group' do
        let(:cluster_link) { "<a href=\"/groups/root_group/-/clusters/#{cluster.id}\">#{cluster.name}</a>" }

        it 'returns the group path' do
          expect(subject).to eq("root_group / #{cluster_link}")
        end
      end

      context 'with multiple parent groups', :nested_groups do
        let(:sub_group) { create(:group, name: 'sub_group', parent: root_group) }
        let(:cluster) { create(:cluster, :group, groups: [sub_group]) }

        it 'returns the full path with trailing slash' do
          expect(subject).to include('root_group / sub_group /')
        end
      end

      context 'with deeper nested groups', :nested_groups do
        let(:sub_group) { create(:group, name: 'sub_group', parent: root_group) }
        let(:sub_sub_group) { create(:group, name: 'sub_sub_group', parent: sub_group) }
        let(:cluster) { create(:cluster, :group, groups: [sub_sub_group]) }

        it 'includes an horizontal ellipsis' do
          expect(subject).to include('ellipsis_h')
        end
      end
    end
  end
end

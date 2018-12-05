# frozen_string_literal: true

require 'spec_helper'

describe ClustersHelper do
  describe '#cluster_group_path_display' do
    let(:group) { create(:group, name: 'group') }
    let(:cluster) { create(:cluster, cluster_type: :group_type, groups: [group]) }
    let(:clusterable) { group }

    subject { helper.cluster_group_path_display(cluster, clusterable) }

    it 'returns nothing' do
      is_expected.to be_nil
    end

    context 'for another clusterable' do
      let(:clusterable) { create(:group) }

      it 'returns the group path' do
        is_expected.to eq('group / ')
      end
    end

    context 'for a project cluster' do
      let(:cluster) { create(:cluster, :project) }
      let(:clusterable) { cluster.project }

      it 'returns nothing' do
        is_expected.to be_nil
      end
    end
  end

  describe '#group_path_shortened' do
    let(:group) { create(:group, name: 'group') }

    subject { helper.group_path_shortened(group) }

    it 'returns the group name with trailing slash' do
      is_expected.to eq('group / ')
    end

    it 'escapes group name' do
      expect(CGI).to receive(:escapeHTML).with('group / ').and_call_original

      subject
    end

    context 'subgroup', :nested_groups do
      let(:root_group) { create(:group, name: 'root') }
      let(:group) { create(:group, name: 'group', parent: root_group) }

      it 'returns the full path with trailing slash' do
        is_expected.to eq('root / group / ')
      end

      it 'escapes group names' do
        expect(CGI).to receive(:escapeHTML).with('root / ').and_call_original
        expect(CGI).to receive(:escapeHTML).with('group / ').and_call_original

        subject
      end

      context 'deeper nested' do
        let(:next_group) { create(:group, name: 'next', parent: root_group) }
        let(:group) { create(:group, name: 'group', parent: next_group) }

        it 'returns a shorted path with trailing slash' do
          is_expected.to eq('root / &hellip; / group / ')
        end
      end
    end
  end
end

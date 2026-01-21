# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::GroupGroupLinksFinder, feature_category: :groups_and_projects do
  describe '#execute' do
    let_it_be(:invited_group) { create(:group) }

    let_it_be(:group) { create(:group) }
    let_it_be(:subgroup) { create(:group, parent: group) }
    let_it_be(:project) { create(:project, group: subgroup) }

    let_it_be(:group_link_dev) do
      create(:group_group_link, :developer, shared_group: group, shared_with_group: invited_group)
    end

    let_it_be(:group_link_guest) do
      create(:group_group_link, :guest, shared_group: subgroup, shared_with_group: invited_group)
    end

    let(:params) { {} }

    subject { described_class.new(project, params).execute }

    it 'returns group links' do
      is_expected.to contain_exactly(group_link_dev, group_link_guest)
    end

    context 'with max_access param' do
      let(:params) { { max_access: true } }

      it 'returns group link with highest access level' do
        is_expected.to contain_exactly(group_link_dev)
      end

      context 'when has direct project link with higher access level' do
        let_it_be(:project_link) { create(:project_group_link, :maintainer, project: project, group: invited_group) }

        it 'does not return group links' do
          is_expected.to be_empty
        end
      end

      context 'when has direct project link with lower access level' do
        let_it_be(:project_link) { create(:project_group_link, :guest, project: project, group: invited_group) }

        it 'returns group link with highest access level' do
          is_expected.to contain_exactly(group_link_dev)
        end
      end
    end

    context 'with search param' do
      let(:params) { { search: invited_group.name } }

      it 'returns matching group links' do
        is_expected.to contain_exactly(group_link_dev, group_link_guest)
      end

      context 'when search does not match' do
        let(:params) { { search: 'non-existent-group' } }

        it { is_expected.to be_empty }
      end
    end

    context 'when project is not in a group' do
      let_it_be(:user) { create(:user, :with_namespace) }
      let_it_be(:project) { create(:project, namespace: user.namespace) }

      it { is_expected.to be_empty }
    end
  end
end

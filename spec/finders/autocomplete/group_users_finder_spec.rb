# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Autocomplete::GroupUsersFinder, feature_category: :text_editors do
  let_it_be(:parent_group) { create(:group) }
  let_it_be(:group) { create(:group, parent: parent_group) }
  let_it_be(:subgroup) { create(:group, parent: group) }

  let_it_be(:parent_group_project) { create(:project, namespace: parent_group) }
  let_it_be(:group_project) { create(:project, namespace: group) }
  let_it_be(:subgroup_project) { create(:project, namespace: subgroup) }

  let(:finder) { described_class.new(group: group) }

  describe '#execute' do
    context 'with group members' do
      let_it_be(:parent_group_member) { create(:user, developer_of: parent_group) }
      let_it_be(:group_member) { create(:user, developer_of: group) }
      let_it_be(:subgroup_member) { create(:user, developer_of: subgroup) }

      let_it_be(:other_group) { create(:group) }
      let_it_be(:other_group_member) { create(:user, developer_of: other_group) }

      it 'returns members of groups in the hierarchy' do
        expect(finder.execute).to contain_exactly(
          parent_group_member,
          group_member,
          subgroup_member
        )
      end
    end

    context 'with project members' do
      let_it_be(:parent_group_project_member) { create(:user, developer_of: parent_group_project) }
      let_it_be(:group_project_member) { create(:user, developer_of: group_project) }
      let_it_be(:subgroup_project_member) { create(:user, developer_of: subgroup_project) }

      it 'returns members of descendant projects' do
        expect(finder.execute).to contain_exactly(
          group_project_member,
          subgroup_project_member
        )
      end
    end

    context 'with invited group members' do
      let_it_be(:invited_group) { create(:group) }
      let_it_be(:invited_group_user) { create(:user, developer_of: invited_group) }

      it 'returns members of groups invited to this group' do
        create(:group_group_link, shared_group: group, shared_with_group: invited_group)

        expect(finder.execute).to contain_exactly(invited_group_user)
      end

      it 'returns members of groups invited to an ancestor group' do
        create(:group_group_link, shared_group: parent_group, shared_with_group: invited_group)

        expect(finder.execute).to contain_exactly(invited_group_user)
      end

      it 'returns members of groups invited to a descendant group' do
        create(:group_group_link, shared_group: subgroup, shared_with_group: invited_group)

        expect(finder.execute).to contain_exactly(invited_group_user)
      end

      it 'returns members of groups invited to a child project' do
        create(:project_group_link, project: group_project, group: invited_group)

        expect(finder.execute).to contain_exactly(invited_group_user)
      end

      it 'returns members of groups invited to a descendant project' do
        create(:project_group_link, project: subgroup_project, group: invited_group)

        expect(finder.execute).to contain_exactly(invited_group_user)
      end

      it 'does not return members of groups invited to a project of an ancestor group' do
        create(:project_group_link, project: parent_group_project, group: invited_group)

        expect(finder.execute).to be_empty
      end
    end
  end
end

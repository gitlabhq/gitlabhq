# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::AcceptingGroupTransfersFinder, feature_category: :groups_and_projects do
  let_it_be(:current_user) { create(:user) }

  let_it_be(:great_grandparent_group) do
    create(:group, name: 'great grandparent group', path: 'great-grandparent-group')
  end

  let_it_be(:grandparent_group) { create(:group, parent: great_grandparent_group) }
  let_it_be(:parent_group) { create(:group, parent: grandparent_group) }
  let_it_be(:child_group) { create(:group, parent: parent_group) }
  let_it_be(:grandchild_group) { create(:group, parent: child_group) }
  let_it_be(:group_where_user_has_owner_access) do
    create(:group, name: 'owner access group', path: 'owner-access-group').tap do |group|
      group.add_owner(current_user)
    end
  end

  let_it_be(:subgroup_of_group_where_user_has_owner_access) do
    create(:group, parent: group_where_user_has_owner_access)
  end

  let_it_be(:group_where_user_has_developer_access) do
    create(:group).tap do |group|
      group.add_developer(current_user)
    end
  end

  let_it_be(:shared_with_group_where_direct_owner_as_guest) { create(:group) }
  let_it_be(:shared_with_group_where_direct_owner_as_owner) { create(:group) }
  let_it_be(:subgroup_of_shared_with_group_where_direct_owner_as_owner) do
    create(:group, parent: shared_with_group_where_direct_owner_as_owner)
  end

  let(:params) { {} }

  describe '#execute' do
    before_all do
      create(
        :group_group_link, :owner,
        shared_with_group: group_where_user_has_owner_access,
        shared_group: shared_with_group_where_direct_owner_as_owner
      )

      create(
        :group_group_link, :guest,
        shared_with_group: group_where_user_has_owner_access,
        shared_group: shared_with_group_where_direct_owner_as_guest
      )
    end

    let(:group_to_be_transferred) { parent_group }

    subject(:result) do
      described_class.new(current_user, group_to_be_transferred, params).execute
    end

    context 'when the user does not have the rights to transfer the group' do
      before do
        group_to_be_transferred.root_ancestor.add_developer(current_user)
      end

      it 'returns empty result' do
        expect(result).to be_empty
      end
    end

    context 'when the user has the rights to transfer the group' do
      before do
        group_to_be_transferred.root_ancestor.add_owner(current_user)
      end

      it 'does not return empty result' do
        expect(result).not_to be_empty
      end

      it 'excludes the descendants of the group to be transferred' do
        expect(result).not_to include(child_group, grandchild_group)
      end

      it 'excludes the immediate parent of the group to be transferred' do
        expect(result).not_to include(grandparent_group)
      end

      it 'excludes the groups where the user does not have OWNER access' do
        expect(result).not_to include(group_where_user_has_developer_access)
      end

      it 'excludes the groups arising from group shares where the user does not have OWNER access' do
        expect(result).not_to include(shared_with_group_where_direct_owner_as_guest)
      end

      it 'includes ancestors, except immediate parent of the group to be transferred' do
        expect(result).to include(great_grandparent_group)
      end

      it 'includes the other groups where the user has OWNER access' do
        expect(result).to include(group_where_user_has_owner_access)
      end

      it 'includes the other groups where the user has OWNER access through inherited membership' do
        expect(result).to include(subgroup_of_group_where_user_has_owner_access)
      end

      it 'includes the groups where the user has OWNER access through group shares' do
        expect(result).to include(
          shared_with_group_where_direct_owner_as_owner,
          subgroup_of_shared_with_group_where_direct_owner_as_owner
        )
      end

      context 'on searching with a specific term' do
        let(:params) { { search: 'great grandparent group' } }

        it 'includes only the groups where the term matches the group name or path' do
          expect(result).to contain_exactly(great_grandparent_group)
        end
      end

      context 'on searching with multiple matches' do
        let(:params) { { search: 'great-grandparent-group' } }
        let(:other_groups) { [] }

        before do
          2.times do
            # app/finders/group/base.rb adds an ORDER BY path, so create a group with 1 in the front.
            group = create(:group, parent: great_grandparent_group, path: "1-#{SecureRandom.hex}")
            group.add_owner(current_user)
            other_groups << group
          end
        end

        it 'prioritizes exact matches first' do
          expect(result.first).to eq(great_grandparent_group)
          expect(result[1..]).to match_array(other_groups)
        end
      end
    end
  end
end

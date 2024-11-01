# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::AcceptingProjectTransfersFinder, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }
  let_it_be(:group_where_direct_owner) { create(:group) }
  let_it_be(:group_where_direct_owner_with_admin_project_creation_level) do
    create(:group, project_creation_level: Gitlab::Access::ADMINISTRATOR_PROJECT_ACCESS)
  end

  let_it_be(:subgroup_of_group_where_direct_owner) { create(:group, parent: group_where_direct_owner) }
  let_it_be(:group_where_direct_maintainer) { create(:group) }

  let_it_be(:group_where_direct_maintainer_but_cant_create_projects) do
    create(:group, project_creation_level: Gitlab::Access::NO_ONE_PROJECT_ACCESS)
  end

  let_it_be(:group_where_direct_developer) { create(:group) }
  let_it_be(:shared_with_group_where_direct_owner_as_owner) { create(:group) }
  let_it_be(:shared_with_group_where_direct_owner_as_guest) { create(:group) }
  let_it_be(:shared_with_group_where_direct_owner_as_maintainer) { create(:group) }
  let_it_be(:shared_with_group_where_direct_developer_as_owner) { create(:group) }
  let_it_be(:subgroup_of_shared_with_group_where_direct_owner_as_maintainer) do
    create(:group, parent: shared_with_group_where_direct_owner_as_maintainer)
  end

  before do
    group_where_direct_owner.add_owner(user)
    group_where_direct_owner_with_admin_project_creation_level.add_owner(user)
    group_where_direct_maintainer.add_maintainer(user)
    group_where_direct_developer.add_developer(user)

    create(
      :group_group_link, :owner,
      shared_with_group: group_where_direct_owner,
      shared_group: shared_with_group_where_direct_owner_as_owner
    )

    create(
      :group_group_link, :guest,
      shared_with_group: group_where_direct_owner,
      shared_group: shared_with_group_where_direct_owner_as_guest
    )

    create(
      :group_group_link, :maintainer,
      shared_with_group: group_where_direct_owner,
      shared_group: shared_with_group_where_direct_owner_as_maintainer
    )

    create(
      :group_group_link, :owner,
      shared_with_group: group_where_direct_developer,
      shared_group: shared_with_group_where_direct_developer_as_owner
    )
  end

  describe '#execute' do
    subject(:result) { described_class.new(user).execute }

    it 'only returns groups where the user has access to transfer projects to' do
      expect(result).to match_array([
        group_where_direct_owner,
        subgroup_of_group_where_direct_owner,
        group_where_direct_maintainer,
        shared_with_group_where_direct_owner_as_owner,
        shared_with_group_where_direct_owner_as_maintainer,
        subgroup_of_shared_with_group_where_direct_owner_as_maintainer
      ])
    end

    context 'with admin user', :enable_admin_mode do
      let_it_be(:user) { create(:admin) }

      it 'returns all accessible groups including with admin project creation level' do
        expect(result).to match_array([
          group_where_direct_owner,
          subgroup_of_group_where_direct_owner,
          group_where_direct_maintainer,
          shared_with_group_where_direct_owner_as_owner,
          shared_with_group_where_direct_owner_as_maintainer,
          subgroup_of_shared_with_group_where_direct_owner_as_maintainer,
          group_where_direct_owner_with_admin_project_creation_level
        ])
      end
    end
  end
end

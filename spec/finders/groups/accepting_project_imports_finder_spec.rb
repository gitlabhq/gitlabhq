# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::AcceptingProjectImportsFinder, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let_it_be(:group_where_direct_owner) { create(:group) }
  let_it_be(:subgroup_of_group_where_direct_owner) { create(:group, parent: group_where_direct_owner) }
  let_it_be(:group_where_direct_maintainer) { create(:group) }
  let_it_be(:group_where_direct_maintainer_but_cant_create_projects) do
    create(:group, project_creation_level: Gitlab::Access::NO_ONE_PROJECT_ACCESS)
  end

  let_it_be(:group_where_direct_developer_but_developers_cannot_create_projects) { create(:group) }
  let_it_be(:group_where_direct_developer) do
    create(:group, project_creation_level: Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS)
  end

  let_it_be(:shared_with_group_where_direct_owner_as_owner) { create(:group) }

  let_it_be(:shared_with_group_where_direct_owner_as_developer) do
    create(:group, project_creation_level: Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS)
  end

  let_it_be(:shared_with_group_where_direct_owner_as_developer_but_developers_cannot_create_projects) do
    create(:group)
  end

  let_it_be(:shared_with_group_where_direct_developer_as_maintainer) do
    create(:group, project_creation_level: Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS)
  end

  let_it_be(:shared_with_group_where_direct_owner_as_guest) { create(:group) }
  let_it_be(:shared_with_group_where_direct_owner_as_maintainer) { create(:group) }
  let_it_be(:shared_with_group_where_direct_developer_as_owner) do
    create(:group, project_creation_level: Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS)
  end

  let_it_be(:subgroup_of_shared_with_group_where_direct_owner_as_maintainer) do
    create(:group, parent: shared_with_group_where_direct_owner_as_maintainer)
  end

  before do
    group_where_direct_owner.add_owner(user)
    group_where_direct_maintainer.add_maintainer(user)
    group_where_direct_developer_but_developers_cannot_create_projects.add_developer(user)
    group_where_direct_developer.add_developer(user)

    create(:group_group_link, :owner,
      shared_with_group: group_where_direct_owner,
      shared_group: shared_with_group_where_direct_owner_as_owner
    )

    create(:group_group_link, :developer,
      shared_with_group: group_where_direct_owner,
      shared_group: shared_with_group_where_direct_owner_as_developer_but_developers_cannot_create_projects
    )

    create(:group_group_link, :maintainer,
      shared_with_group: group_where_direct_developer,
      shared_group: shared_with_group_where_direct_developer_as_maintainer
    )

    create(:group_group_link, :developer,
      shared_with_group: group_where_direct_owner,
      shared_group: shared_with_group_where_direct_owner_as_developer
    )

    create(:group_group_link, :guest,
      shared_with_group: group_where_direct_owner,
      shared_group: shared_with_group_where_direct_owner_as_guest
    )

    create(:group_group_link, :maintainer,
      shared_with_group: group_where_direct_owner,
      shared_group: shared_with_group_where_direct_owner_as_maintainer
    )

    create(:group_group_link, :owner,
      shared_with_group: group_where_direct_developer_but_developers_cannot_create_projects,
      shared_group: shared_with_group_where_direct_developer_as_owner
    )
  end

  describe '#execute' do
    subject(:result) { described_class.new(user).execute }

    it 'only returns groups where the user has access to import projects' do
      expect(result).to match_array([
        group_where_direct_owner,
        subgroup_of_group_where_direct_owner,
        group_where_direct_maintainer,
        # groups arising from group shares
        shared_with_group_where_direct_owner_as_owner,
        shared_with_group_where_direct_owner_as_maintainer,
        subgroup_of_shared_with_group_where_direct_owner_as_maintainer
      ])

      expect(result).not_to include(group_where_direct_developer)
      expect(result).not_to include(shared_with_group_where_direct_developer_as_owner)
      expect(result).not_to include(shared_with_group_where_direct_developer_as_maintainer)
      expect(result).not_to include(shared_with_group_where_direct_owner_as_developer)
    end
  end
end

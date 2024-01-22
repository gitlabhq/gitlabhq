# frozen_string_literal: true

module Groups
  class AcceptingProjectTransfersFinder
    def initialize(current_user)
      @current_user = current_user
    end

    def execute
      groups_accepting_project_transfers =
        [
          current_user.manageable_groups,
          managable_groups_originating_from_group_shares
        ]

      groups = ::Group.from_union(groups_accepting_project_transfers)

      groups.project_creation_allowed(current_user)
    end

    private

    attr_reader :current_user

    def managable_groups_originating_from_group_shares
      GroupGroupLink
        .with_owner_or_maintainer_access
        .groups_accessible_via(
          groups_that_user_has_owner_or_maintainer_access_via_direct_membership
          .select(:id)
        )
    end

    def groups_that_user_has_owner_or_maintainer_access_via_direct_membership
      # Only maintainers or above in a group has access to transfer projects to that group
      current_user.owned_or_maintainers_groups
    end
  end
end

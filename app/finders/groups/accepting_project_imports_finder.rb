# frozen_string_literal: true

module Groups
  class AcceptingProjectImportsFinder
    def initialize(current_user)
      @current_user = current_user
    end

    def execute
      ::Group.from_union(
        [
          current_user.manageable_groups,
          managable_groups_originating_from_group_shares
        ]
      )
    end

    private

    attr_reader :current_user

    def managable_groups_originating_from_group_shares
      GroupGroupLink
        .with_owner_or_maintainer_access
        .groups_accessible_via(
          current_user.owned_or_maintainers_groups
          .select(:id)
        )
    end
  end
end

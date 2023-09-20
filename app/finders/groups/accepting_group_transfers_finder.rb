# frozen_string_literal: true

module Groups
  class AcceptingGroupTransfersFinder < Base
    include Gitlab::Utils::StrongMemoize

    def initialize(current_user, group_to_be_transferred, params = {})
      @current_user = current_user
      @group_to_be_transferred = group_to_be_transferred
      @params = params
    end

    def execute
      return Group.none unless can_transfer_group?

      items = find_all_groups

      # Search will perform an ORDER BY to ensure exact matches are returned first.
      return by_search(items, exact_matches_first: true) if params[:search].present?

      sort(items)
    end

    private

    attr_reader :current_user, :group_to_be_transferred, :params

    def find_groups
      GroupsFinder.new( # rubocop: disable CodeReuse/Finder
        current_user,
        min_access_level: Gitlab::Access::OWNER,
        exclude_group_ids: exclude_groups
      ).execute.without_order
    end

    def find_all_groups
      ::Namespace.from_union(
        [
          find_groups,
          groups_originating_from_group_shares_with_owner_access
        ]
      )
    end

    def groups_originating_from_group_shares_with_owner_access
      GroupGroupLink
        .with_owner_access
        .groups_accessible_via(
          current_user.owned_groups.select(:id)
        ).id_not_in(exclude_groups)
    end

    def exclude_groups
      strong_memoize(:exclude_groups) do
        exclude_groups = group_to_be_transferred.self_and_descendants.pluck_primary_key
        exclude_groups << group_to_be_transferred.parent_id if group_to_be_transferred.parent_id

        exclude_groups
      end
    end

    def can_transfer_group?
      Ability.allowed?(current_user, :admin_group, group_to_be_transferred)
    end
  end
end

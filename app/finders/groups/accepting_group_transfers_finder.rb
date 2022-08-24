# frozen_string_literal: true

module Groups
  class AcceptingGroupTransfersFinder < Base
    def initialize(current_user, group_to_be_transferred, params = {})
      @current_user = current_user
      @group_to_be_transferred = group_to_be_transferred
      @params = params
    end

    def execute
      return Group.none unless can_transfer_group?

      items = find_groups
      items = by_search(items)

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

    def exclude_groups
      exclude_groups = group_to_be_transferred.self_and_descendants.pluck_primary_key
      exclude_groups << group_to_be_transferred.parent_id if group_to_be_transferred.parent_id

      exclude_groups
    end

    def can_transfer_group?
      Ability.allowed?(current_user, :admin_group, group_to_be_transferred)
    end
  end
end

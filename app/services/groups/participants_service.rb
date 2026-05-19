# frozen_string_literal: true

module Groups
  class ParticipantsService < Groups::BaseService
    include Gitlab::Utils::StrongMemoize
    include Users::ParticipableService

    def execute(noteable)
      @noteable = noteable

      participants =
        noteable_owner +
        participants_in_noteable +
        group_hierarchy_users

      participants += groups unless relation_at_search_limit?(group_hierarchy_users)

      render_participants_as_hash(participants.uniq)
    end

    private

    def participation_object
      group
    end

    def group_hierarchy_users
      return [] unless group

      relation = Autocomplete::GroupUsersFinder.new(group: group, current_user: current_user).execute

      filter_and_sort_users(relation)
    end
    strong_memoize_attr :group_hierarchy_users
  end
end

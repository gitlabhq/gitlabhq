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
        group_hierarchy_users +
        mentioned_users(group_members_relation)

      participants += groups unless relation_at_search_limit?(group_hierarchy_users)

      render_participants_as_hash(participants.uniq)
    end

    private

    def participation_object
      group
    end

    def group_members_relation
      return unless group

      Autocomplete::GroupUsersFinder.new(group: group, current_user: current_user).execute
    end
    strong_memoize_attr :group_members_relation

    def group_hierarchy_users
      return [] unless group_members_relation

      filter_and_sort_users(group_members_relation)
    end
    strong_memoize_attr :group_hierarchy_users
  end
end

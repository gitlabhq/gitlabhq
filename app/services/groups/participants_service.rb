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
        all_members +
        group_hierarchy_users +
        groups

      render_participants_as_hash(participants.uniq)
    end

    private

    def all_members
      return [] if group.nil? || Feature.enabled?(:disable_all_mention)

      [{ username: "all", name: "All Group Members", count: group.users_count }]
    end

    def group_hierarchy_users
      return [] unless group

      relation = Autocomplete::GroupUsersFinder.new(group: group).execute

      filter_and_sort_users(relation)
    end
  end
end

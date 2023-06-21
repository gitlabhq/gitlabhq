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
        groups +
        group_members

      render_participants_as_hash(participants.uniq)
    end

    private

    def all_members
      return [] if Feature.enabled?(:disable_all_mention)

      count = group_members.count
      [{ username: "all", name: "All Group Members", count: count }]
    end

    def group_members
      return [] unless group

      sorted(
        group.direct_and_indirect_users(share_with_groups: group.member?(current_user))
      )
    end
    strong_memoize_attr :group_members
  end
end

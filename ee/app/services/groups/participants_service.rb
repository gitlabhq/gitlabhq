module Groups
  class ParticipantsService < BaseService
    include Users::ParticipableService

    def execute(noteable)
      @noteable = noteable

      participants = noteable_owner + participants_in_noteable + all_members + groups + group_members
      participants.uniq
    end

    def all_members
      count = group_members.count
      [{ username: "all", name: "All Group Members", count: count }]
    end

    def group_members
      return [] unless noteable

      @group_members ||= sorted(noteable.group.direct_and_indirect_users)
    end
  end
end

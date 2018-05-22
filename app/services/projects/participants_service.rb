module Projects
  class ParticipantsService < BaseService
    include Users::ParticipableService

    def execute(noteable)
      @noteable = noteable

      project_members = sorted(project.team.members)
      participants = noteable_owner + participants_in_noteable + all_members + groups + project_members
      participants.uniq
    end

    def all_members
      count = project.team.members.flatten.count
      [{ username: "all", name: "All Project and Group Members", count: count }]
    end
  end
end

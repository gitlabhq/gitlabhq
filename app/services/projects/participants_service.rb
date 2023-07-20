# frozen_string_literal: true

module Projects
  class ParticipantsService < BaseService
    include Users::ParticipableService

    def execute(noteable)
      @noteable = noteable

      participants =
        noteable_owner +
        participants_in_noteable +
        all_members +
        groups +
        project_members

      render_participants_as_hash(participants.uniq)
    end

    def project_members
      @project_members ||= sorted(project.authorized_users)
    end

    def all_members
      return [] if Feature.enabled?(:disable_all_mention)

      [{ username: "all", name: "All Project and Group Members", count: project_members.count }]
    end
  end
end

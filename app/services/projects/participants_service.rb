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
        project_members +
        groups

      render_participants_as_hash(participants.uniq)
    end

    def project_members
      filter_and_sort_users(project_members_relation)
    end

    def all_members
      return [] if Feature.enabled?(:disable_all_mention)

      [{ username: "all", name: "All Project and Group Members", count: project_members_relation.count }]
    end

    def project_members_relation
      project.authorized_users
    end
  end
end

# frozen_string_literal: true

module Projects
  class ParticipantsService < BaseService
    include Gitlab::Utils::StrongMemoize
    include Users::ParticipableService

    def execute(noteable)
      @noteable = noteable

      participants =
        noteable_owner +
        participants_in_noteable +
        all_members +
        project_members

      participants += groups(organization: organization) unless relation_at_search_limit?(project_members)
      participants = organization_user_details_for_participants(participants.uniq)

      render_participants_as_hash(participants)
    end

    def project_members
      filter_and_sort_users(project_members_relation)
    end
    strong_memoize_attr :project_members

    def all_members
      return [] if Feature.enabled?(:disable_all_mention)

      [{ username: "all", name: "All Project and Group Members", count: project_members_relation.count }]
    end

    def project_members_relation
      project.authorized_users.with_organization_user_details
    end

    private

    def organization
      project.organization
    end
    strong_memoize_attr :organization

    # for users that have an OrganizationUserDetail for the current organization, use this instead
    # of the User model for rendering username, display_name, and other details
    # details should be pre-loaded to avoid N+1 queries
    def organization_user_details_for_participants(participants)
      return participants unless Feature.enabled?(:organization_users_internal, organization)

      participants.map do |participant|
        next participant unless participant.is_a?(User)

        detail = participant.organization_user_details.to_a.find do |det|
          det.organization == organization
        end

        detail.presence || participant
      end
    end
  end
end

Projects::ParticipantsService.prepend_mod_with('Projects::ParticipantsService')

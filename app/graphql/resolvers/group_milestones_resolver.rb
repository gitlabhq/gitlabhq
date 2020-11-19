# frozen_string_literal: true
# rubocop:disable Graphql/ResolverType (inherited from MilestonesResolver)

module Resolvers
  class GroupMilestonesResolver < MilestonesResolver
    argument :include_descendants, GraphQL::BOOLEAN_TYPE,
             required: false,
             description: 'Also return milestones in all subgroups and subprojects'

    type Types::MilestoneType.connection_type, null: true

    private

    def parent_id_parameters(args)
      return { group_ids: parent.id } unless args[:include_descendants].present?

      {
        group_ids: parent.self_and_descendants.public_or_visible_to_user(current_user).select(:id),
        project_ids: group_projects.with_issues_or_mrs_available_for_user(current_user)
      }
    end

    def group_projects
      GroupProjectsFinder.new(
        group: parent,
        current_user: current_user,
        options: { include_subgroups: true }
      ).execute
    end
  end
end

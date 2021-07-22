# frozen_string_literal: true
# rubocop:disable Graphql/ResolverType (inherited from MilestonesResolver)

module Resolvers
  class ProjectMilestonesResolver < MilestonesResolver
    argument :include_ancestors, GraphQL::Types::Boolean,
             required: false,
             description: "Also return milestones in the project's parent group and its ancestors."

    type Types::MilestoneType.connection_type, null: true

    private

    def parent_id_parameters(args)
      return { project_ids: parent.id } unless args[:include_ancestors].present? && parent.group.present?

      {
        group_ids: parent.group.self_and_ancestors.select(:id),
        project_ids: parent.id
      }
    end
  end
end

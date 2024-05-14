# frozen_string_literal: true

module Resolvers
  class ProjectMilestonesResolver < MilestonesResolver
    include ::API::Concerns::Milestones::GroupProjectParams

    argument :include_ancestors, GraphQL::Types::Boolean,
      required: false,
      description: "Also return milestones in the project's parent group and its ancestors."

    type Types::MilestoneType.connection_type, null: true

    private

    def parent_id_parameters(args)
      project_finder_params(parent, args)
    end
  end
end

# frozen_string_literal: true

module Resolvers
  class GroupMilestonesResolver < MilestonesResolver
    include ::API::Concerns::Milestones::GroupProjectParams

    argument :include_ancestors, GraphQL::Types::Boolean,
      required: false,
      description: 'Include milestones from all parent groups.'
    argument :include_descendants, GraphQL::Types::Boolean,
      required: false,
      description: 'Include milestones from all subgroups and subprojects.'

    type Types::MilestoneType.connection_type, null: true

    private

    def parent_id_parameters(args)
      group_finder_params(parent, args)
    end

    def preloads
      super.merge({ subgroup_milestone: :group })
    end
  end
end

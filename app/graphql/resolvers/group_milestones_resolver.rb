# frozen_string_literal: true

module Resolvers
  class GroupMilestonesResolver < MilestonesResolver
    argument :include_descendants, GraphQL::Types::Boolean,
             required: false,
             description: 'Include milestones from all subgroups and subprojects.'
    argument :include_ancestors, GraphQL::Types::Boolean,
             required: false,
             description: 'Include milestones from all parent groups.'

    type Types::MilestoneType.connection_type, null: true

    private

    def parent_id_parameters(args)
      include_ancestors = args[:include_ancestors].present?
      include_descendants = args[:include_descendants].present?
      return { group_ids: parent.id } unless include_ancestors || include_descendants

      group_ids = if include_ancestors && include_descendants
                    parent.self_and_hierarchy
                  elsif include_ancestors
                    parent.self_and_ancestors
                  else
                    parent.self_and_descendants
                  end

      project_ids = if include_descendants
                      group_projects.with_issues_or_mrs_available_for_user(current_user)
                    else
                      nil
                    end

      {
        group_ids: group_ids.public_or_visible_to_user(current_user).select(:id),
        project_ids: project_ids
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

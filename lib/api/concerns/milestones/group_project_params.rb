# frozen_string_literal: true

# This DRYs up some methods used by both the GraphQL and REST milestone APIs
module API
  module Concerns
    module Milestones
      module GroupProjectParams
        extend ActiveSupport::Concern

        private

        def project_finder_params(parent, params)
          return { project_ids: parent.id } unless params[:include_ancestors].present? && parent.group.present?

          {
            group_ids: parent.group.self_and_ancestors.select(:id),
            project_ids: parent.id
          }
        end

        def group_finder_params(parent, params)
          include_ancestors = params[:include_ancestors].present?
          include_descendants = params[:include_descendants].present?
          return { group_ids: parent.id } unless include_ancestors || include_descendants

          group_ids = if include_ancestors && include_descendants
                        parent.self_and_hierarchy
                      elsif include_ancestors
                        parent.self_and_ancestors
                      else
                        parent.self_and_descendants
                      end

          if include_descendants
            project_ids = group_projects(parent).with_issues_or_mrs_available_for_user(current_user)
          end

          {
            group_ids: group_ids.public_or_visible_to_user(current_user).select(:id),
            project_ids: project_ids
          }
        end

        def group_projects(parent)
          GroupProjectsFinder.new(
            group: parent,
            current_user: current_user,
            options: { include_subgroups: true }
          ).execute
        end
      end
    end
  end
end

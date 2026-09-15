# frozen_string_literal: true

module Mcp
  module Tools
    module Concerns
      module ResourceFinder
        include Gitlab::ResourceLookup

        private

        def find_project!(project_id, ability: :read_project)
          project = find_project(project_id)

          unless project && Ability.allowed?(current_user, ability, project)
            raise StandardError, "Project '#{project_id}' not found or inaccessible"
          end

          project
        end

        def find_project(project_id)
          raise ArgumentError, "project_id must be a string" unless project_id.is_a?(String)

          lookup_project(project_id)
        end

        def find_group!(group_id, ability: :read_group)
          group = lookup_group(group_id)

          unless group && Ability.allowed?(current_user, ability, group)
            raise StandardError, "Group '#{group_id}' not found or inaccessible"
          end

          group
        end

        def find_parent_by_id_or_path!(parent_type, identifier)
          parent_type == :project ? find_project!(identifier) : find_group!(identifier)
        end

        def find_work_item_in_parent!(parent, iid)
          finder_params = build_work_item_finder_params(parent)

          work_item = ::WorkItems::WorkItemsFinder.new(
            current_user,
            finder_params
          ).execute.find_by_iid(iid)

          raise ArgumentError, "Work item ##{iid} not found or inaccessible" unless work_item

          work_item
        end

        def build_work_item_finder_params(parent)
          if parent.is_a?(Project)
            { project_id: parent.id }
          elsif parent.is_a?(Group)
            { group_id: parent.id, include_descendants: false }
          else
            {}
          end
        end
      end
    end
  end
end

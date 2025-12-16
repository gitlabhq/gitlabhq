# frozen_string_literal: true

module Mcp
  module Tools
    module Concerns
      module ResourceFinder
        private

        def find_project(project_id)
          raise ArgumentError, "project_id must be a string" unless project_id.is_a?(String)

          projects = ::Project.without_deleted.not_hidden
          project = if ::API::Helpers::INTEGER_ID_REGEX.match?(project_id)
                      projects.find_by(id: project_id) # rubocop: disable CodeReuse/ActiveRecord -- no need to redefine a scope for the built-in method
                    elsif project_id.include?('/')
                      projects.find_by_full_path(project_id, follow_redirects: true)
                    end

          raise StandardError, "Project '#{project_id}' not found or inaccessible" unless project

          project
        end

        def find_group(group_id)
          group = if ::API::Helpers::INTEGER_ID_REGEX.match?(group_id)
                    ::Group.id_in(group_id).first
                  else
                    ::Group.find_by_full_path(group_id)
                  end

          raise StandardError, "Group '#{group_id}' not found or inaccessible" unless group

          group
        end

        def find_parent_by_id_or_path(parent_type, identifier)
          parent = parent_type == :project ? find_project(identifier) : find_group(identifier)

          authorize_parent_access!(parent, parent_type, identifier)

          parent
        end

        def find_work_item_in_parent(parent, iid)
          finder_params = build_work_item_finder_params(parent)

          work_item = ::WorkItems::WorkItemsFinder.new(
            current_user,
            finder_params
          ).execute.find_by_iid(iid)

          raise ArgumentError, "Work item ##{iid} not found" unless work_item

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

        def authorize_parent_access!(parent, parent_type, identifier)
          return if can_read_parent?(parent, parent_type)

          raise ArgumentError, "Access denied to #{parent_type}: '#{identifier}'"
        end

        def can_read_parent?(parent, parent_type)
          permission = parent_type == :project ? :read_project : :read_group
          Ability.allowed?(current_user, permission, parent)
        end
      end
    end
  end
end

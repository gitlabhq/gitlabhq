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
      end
    end
  end
end

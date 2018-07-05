module Banzai
  module ReferenceParser
    class ProjectParser < BaseParser
      self.reference_type = :project

      def references_relation
        Project
      end

      def nodes_visible_to_user(user, nodes)
        nodes_projects_hash = lazy { projects_for_nodes(nodes) }
        project_attr = 'data-project'

        readable_project_ids = projects_readable_by_user(nodes_projects_hash.values, user)

        nodes.select do |node|
          if node.has_attribute?(project_attr)
            readable_project_ids.include?(nodes_projects_hash[node].try(:id))
          else
            true
          end
        end
      end

      private

      # Returns an Array of Project ids that can be read by the given user.
      #
      # projects - The projects to reduce down to those readable by the user.
      # user - The User for which to check the projects
      def projects_readable_by_user(projects, user)
        Project.public_or_visible_to_user(user).where("projects.id IN (?)", projects.map(&:id)).pluck(:id)
      end
    end
  end
end

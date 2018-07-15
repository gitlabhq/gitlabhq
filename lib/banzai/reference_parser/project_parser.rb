module Banzai
  module ReferenceParser
    class ProjectParser < BaseParser
      include Gitlab::Utils::StrongMemoize

      self.reference_type = :project

      def references_relation
        Project
      end

      private

      # Returns an Array of Project ids that can be read by the given user.
      #
      # projects - The projects to reduce down to those readable by the user.
      # user - The User for which to check the projects
      def readable_project_ids_for(projects, user)
        strong_memoize(:readable_project_ids_for) do
          Project.public_or_visible_to_user(user).where("projects.id IN (?)", projects.map(&:id)).pluck(:id)
        end
      end

      def can_read_reference?(user, ref_project, node)
        readable_project_ids_for(@projects_for_nodes.values, user).include?(ref_project.try(:id))
      end
    end
  end
end

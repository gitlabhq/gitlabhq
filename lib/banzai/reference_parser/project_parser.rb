# frozen_string_literal: true

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
      # user - The User for which to check the projects
      def readable_project_ids_for(user)
        @project_ids_by_user ||= {}
        @project_ids_by_user[user] ||=
          Project.public_or_visible_to_user(user).where(projects: { id: @projects_for_nodes.values.map(&:id) }).pluck(:id)
      end

      def can_read_reference?(user, ref_project, node)
        readable_project_ids_for(user).include?(ref_project.try(:id))
      end
    end
  end
end

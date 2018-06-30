module Banzai
  module ReferenceParser
    class ProjectParser < BaseParser
      self.reference_type = :project

      def references_relation
        Project
      end

      private

      def can_read_reference?(user, ref_project, node)
        can?(user, :read_project, ref_project)
      end
    end
  end
end

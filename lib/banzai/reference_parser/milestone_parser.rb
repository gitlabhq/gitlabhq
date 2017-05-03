module Banzai
  module ReferenceParser
    class MilestoneParser < BaseParser
      self.reference_type = :milestone

      def references_relation
        Milestone
      end

      private

      def can_read_reference?(user, ref_project)
        can?(user, :read_milestone, ref_project)
      end
    end
  end
end

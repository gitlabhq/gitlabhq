module Banzai
  module ReferenceParser
    class MilestoneParser < BaseParser
      self.reference_type = :milestone

      def references_relation
        Milestone
      end
    end
  end
end

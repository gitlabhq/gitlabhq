module Banzai
  module ReferenceParser
    class MilestoneParser < Parser
      self.reference_type = :milestone

      def references_relation
        Milestone
      end
    end
  end
end

module Banzai
  module ReferenceParser
    class MilestoneParser < Parser
      self.reference_type = :milestone

      def referenced_by(node)
        [LazyReference.new(Milestone, node.attr('data-milestone'))]
      end
    end
  end
end

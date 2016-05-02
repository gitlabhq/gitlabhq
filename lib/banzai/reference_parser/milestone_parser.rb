module Banzai
  module ReferenceParser
    class MilestoneParser < Parser
      self.reference_type = :milestone

      def referenced_by(nodes)
        ids = nodes.map { |node| node.attr('data-milestone') }

        Milestone.where(id: ids)
      end
    end
  end
end

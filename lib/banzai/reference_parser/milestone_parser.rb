module Banzai
  module ReferenceParser
    class MilestoneParser < Parser
      self.reference_type = :milestone

      def referenced_by(nodes)
        ids = unique_attribute_values(nodes, 'data-milestone')

        Milestone.where(id: ids)
      end
    end
  end
end

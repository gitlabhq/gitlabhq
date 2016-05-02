module Banzai
  module ReferenceParser
    class LabelParser < Parser
      self.reference_type = :label

      def referenced_by(nodes)
        ids = nodes.map { |node| node.attr('data-label') }

        Label.where(id: ids)
      end
    end
  end
end

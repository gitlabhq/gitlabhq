module Banzai
  module ReferenceParser
    class LabelParser < Parser
      self.reference_type = :label

      def referenced_by(node)
        [LazyReference.new(Label, node.attr('data-label'))]
      end
    end
  end
end

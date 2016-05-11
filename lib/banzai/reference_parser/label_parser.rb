module Banzai
  module ReferenceParser
    class LabelParser < Parser
      self.reference_type = :label

      def referenced_by(nodes)
        ids = unique_attribute_values(nodes, 'data-label')

        Label.where(id: ids)
      end
    end
  end
end

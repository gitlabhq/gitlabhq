module Banzai
  module ReferenceParser
    class SnippetParser < Parser
      self.reference_type = :snippet

      def referenced_by(nodes)
        ids = unique_attribute_values(nodes, 'data-snippet')

        Snippet.where(id: ids)
      end
    end
  end
end

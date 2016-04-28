module Banzai
  module ReferenceParser
    class SnippetParser < Parser
      self.reference_type = :snippet

      def referenced_by(node)
        [LazyReference.new(Snippet, node.attr('data-snippet'))]
      end
    end
  end
end

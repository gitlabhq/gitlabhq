module Banzai
  module ReferenceParser
    class SnippetParser < Parser
      self.reference_type = :snippet

      def referenced_by(nodes)
        ids = nodes.map { |node| node.attr('data-snippet') }

        Snippet.where(id: ids)
      end
    end
  end
end

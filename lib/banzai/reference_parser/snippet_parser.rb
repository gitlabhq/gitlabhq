module Banzai
  module ReferenceParser
    class SnippetParser < Parser
      self.reference_type = :snippet

      def references_relation
        Snippet
      end
    end
  end
end

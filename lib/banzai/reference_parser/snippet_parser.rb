module Banzai
  module ReferenceParser
    class SnippetParser < BaseParser
      self.reference_type = :snippet

      def references_relation
        Snippet
      end
    end
  end
end

module Banzai
  module ReferenceParser
    class SnippetParser < BaseParser
      self.reference_type = :snippet

      def references_relation
        Snippet
      end

      private

      def can_read_reference?(user, ref_project, node)
        can?(user, :read_project_snippet, referenced_by([node]).first)
      end
    end
  end
end

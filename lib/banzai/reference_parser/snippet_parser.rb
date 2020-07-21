# frozen_string_literal: true

module Banzai
  module ReferenceParser
    class SnippetParser < BaseParser
      self.reference_type = :snippet

      def references_relation
        Snippet
      end

      # Returns all the nodes that are visible to the given user.
      def nodes_visible_to_user(user, nodes)
        snippets = lazy { grouped_objects_for_nodes(nodes, references_relation, self.class.data_attribute) }

        nodes.select do |node|
          if node.has_attribute?(self.class.data_attribute)
            can_read_reference?(user, snippets[node])
          else
            true
          end
        end
      end

      private

      def can_read_reference?(user, snippet)
        can?(user, :read_snippet, snippet)
      end
    end
  end
end

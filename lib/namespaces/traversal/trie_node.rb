# frozen_string_literal: true

module Namespaces
  module Traversal
    class TrieNode
      attr_accessor :children, :end

      class << self
        def build(...)
          new.build(...)
        end
      end

      def initialize
        @children = {}
        @end = false
      end

      def build(traversal_ids)
        traversal_ids.each do |traversal_id|
          next if covered?(traversal_id)

          insert(traversal_id)
        end

        self
      end

      # Bring back all branches in the trie that match the prefix
      # If trie contains [9970, 123] and [9970, 456]
      # prefix_search([9970]) returns [[9970, 123], [9970, 456]]
      def prefix_search(traversal_ids)
        node = self
        traversal_ids.each do |traversal_id|
          return [] unless node.children[traversal_id]

          node = node.children[traversal_id]
        end

        [].tap do |result|
          if node.end
            result << traversal_ids
          else
            result.concat(collect_children(node, traversal_ids.dup))
          end
        end
      end

      # Check if traversal ID is already covered by a broader prefix or included in trie
      # If trie contains [9970, 123] and [9970, 456]
      # covered?([9970]) returns false
      # covered?([9970, 123]) returns true
      # covered?([9970, 123, 789]) returns true
      def covered?(traversal_ids)
        current_node = self

        traversal_ids.each do |traversal_id|
          # If we've hit an end marker, it's covered
          return true if current_node.end

          # If the segment doesn't exist, it's not covered
          return false unless current_node.children[traversal_id]

          current_node = current_node.children[traversal_id]
        end

        current_node.end
      end

      def to_a
        collect_children(self, [])
      end

      private

      # Insert traversal ID into the trie if it's not covered
      def insert(traversal_ids)
        current_node = self

        traversal_ids.each do |traversal_id|
          # If we reach an end marker, this means a broader permission already exists
          break if current_node.end

          # Create new node for this segment if not present
          current_node.children[traversal_id] ||= TrieNode.new
          current_node = current_node.children[traversal_id]
        end

        # Mark the end of the current traversal ID and delete its children
        current_node.children.clear
        current_node.end = true
      end

      def collect_children(node, traversal_ids = [])
        result = []
        result << traversal_ids if node.end

        node.children.each do |traversal_id, child_node|
          result.concat(collect_children(child_node, traversal_ids + [traversal_id]))
        end

        result
      end
    end
  end
end

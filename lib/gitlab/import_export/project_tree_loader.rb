# frozen_string_literal: true

module Gitlab
  module ImportExport
    class ProjectTreeLoader
      def load(path, dedup_entries: false)
        tree_hash = ActiveSupport::JSON.decode(IO.read(path))

        if dedup_entries
          dedup_tree(tree_hash)
        else
          tree_hash
        end
      end

      private

      # This function removes duplicate entries from the given tree recursively
      # by caching nodes it encounters repeatedly. We only consider nodes for
      # which there can actually be multiple equivalent instances (e.g. strings,
      # hashes and arrays, but not `nil`s, numbers or booleans.)
      #
      # The algorithm uses a recursive depth-first descent with 3 cases, starting
      # with a root node (the tree/hash itself):
      # - a node has already been cached; in this case we return it from the cache
      # - a node has not been cached yet but should be; descend into its children
      # - a node is neither cached nor qualifies for caching; this is a no-op
      def dedup_tree(node, nodes_seen = {})
        if nodes_seen.key?(node) && distinguishable?(node)
          yield nodes_seen[node]
        elsif should_dedup?(node)
          nodes_seen[node] = node

          case node
          when Array
            node.each_index do |idx|
              dedup_tree(node[idx], nodes_seen) do |cached_node|
                node[idx] = cached_node
              end
            end
          when Hash
            node.each do |k, v|
              dedup_tree(v, nodes_seen) do |cached_node|
                node[k] = cached_node
              end
            end
          end
        else
          node
        end
      end

      # We do not need to consider nodes for which there cannot be multiple instances
      def should_dedup?(node)
        node && !(node.is_a?(Numeric) || node.is_a?(TrueClass) || node.is_a?(FalseClass))
      end

      # We can only safely de-dup values that are distinguishable. True value objects
      # are always distinguishable by nature. Hashes however can represent entities,
      # which are identified by ID, not value. We therefore disallow de-duping hashes
      # that do not have an `id` field, since we might risk dropping entities that
      # have equal attributes yet different identities.
      def distinguishable?(node)
        if node.is_a?(Hash)
          node.key?('id')
        else
          true
        end
      end
    end
  end
end

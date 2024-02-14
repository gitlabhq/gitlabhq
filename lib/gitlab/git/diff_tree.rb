# frozen_string_literal: true

module Gitlab
  module Git
    # Represents a tree-ish object for git diff-tree command
    # See: https://git-scm.com/docs/git-diff-tree
    class DiffTree
      attr_reader :left_tree_id, :right_tree_id

      def initialize(left_tree_id, right_tree_id)
        @left_tree_id = left_tree_id
        @right_tree_id = right_tree_id
      end
    end
  end
end

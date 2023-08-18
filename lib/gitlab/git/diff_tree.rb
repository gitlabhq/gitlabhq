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

      def self.from_commit(commit)
        return unless commit.tree_id

        parent_tree_id =
          if commit.parent_ids.blank?
            Gitlab::Git::EMPTY_TREE_ID
          else
            parent_id = commit.parent_ids.first
            commit.repository.commit(parent_id).tree_id
          end

        new(parent_tree_id, commit.tree_id)
      end
    end
  end
end

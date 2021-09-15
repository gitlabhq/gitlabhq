# frozen_string_literal: true

module Gitlab
  # Analyse a graph of commits from a push to a branch,
  # for each commit, analyze that if it is the head of a merge request,
  # then what should its merge_commit be, relative to the branch.
  #
  # A----->B----->C----->D   target branch
  # |             ^
  # |             |
  # +-->E----->F--+          merged branch
  #     |     ^
  #     |     |
  #     +->G--+
  #
  # (See merge-commit-analyze-after branch in gitlab-test)
  #
  # Assuming
  # - A is already in remote
  # - B~D are all in its own branch with its own merge request, targeting the target branch
  #
  # When D is finally pushed to the target branch,
  # what are the merge commits for all the other merge requests?
  #
  # We can walk backwards from the HEAD commit D,
  # and find status of its parents.
  # First we determine if commit belongs to the target branch (i.e. A, B, C, D),
  # and then determine its merge commit.
  #
  # +--------+-----------------+--------------+
  # | Commit | Direct ancestor | Merge commit |
  # +--------+-----------------+--------------+
  # | D      | Y               | D            |
  # +--------+-----------------+--------------+
  # | C      | Y               | C            |
  # +--------+-----------------+--------------+
  # | F      |                 | C            |
  # +--------+-----------------+--------------+
  # | B      | Y               | B            |
  # +--------+-----------------+--------------+
  # | E      |                 | C            |
  # +--------+-----------------+--------------+
  # | G      |                 | C            |
  # +--------+-----------------+--------------+
  #
  # By examining the result, it can be said that
  #
  # - If commit is direct ancestor of HEAD, its merge commit is itself.
  # - Otherwise, the merge commit is the same as its child's merge commit.
  #
  class BranchPushMergeCommitAnalyzer
    class CommitDecorator < SimpleDelegator
      attr_accessor :merge_commit
      attr_writer :direct_ancestor # boolean

      def direct_ancestor?
        @direct_ancestor
      end

      # @param child_commit [CommitDecorator]
      # @param first_parent [Boolean] whether `self` is the first parent of `child_commit`
      def set_merge_commit(child_commit:)
        @merge_commit ||= direct_ancestor? ? self : child_commit.merge_commit
      end
    end

    # @param commits [Array] list of commits, must be ordered from the child (tip) of the graph back to the ancestors
    def initialize(commits, relevant_commit_ids: nil)
      @commits = commits
      @id_to_commit = {}
      @commits.each do |commit|
        @id_to_commit[commit.id] = CommitDecorator.new(commit)

        if relevant_commit_ids
          relevant_commit_ids.delete(commit.id)
          break if relevant_commit_ids.empty? # Only limit the analyze up to relevant_commit_ids
        end
      end

      analyze
    end

    def get_merge_commit(id)
      get_commit(id).merge_commit.id
    end

    private

    def analyze
      head_commit = get_commit(@commits.first.id)
      head_commit.direct_ancestor = true
      head_commit.merge_commit = head_commit

      mark_all_direct_ancestors(head_commit)

      # Analyzing a commit requires its child commit be analyzed first,
      # which is the case here since commits are ordered from child to parent.
      @id_to_commit.each_value do |commit|
        analyze_parents(commit)
      end
    end

    def analyze_parents(commit)
      commit.parent_ids.each do |parent_commit_id|
        parent_commit = get_commit(parent_commit_id)

        next unless parent_commit # parent commit may not be part of new commits

        parent_commit.set_merge_commit(child_commit: commit)
      end
    end

    # Mark all direct ancestors.
    # If child commit is a direct ancestor, its first parent is also a direct ancestor.
    # We assume direct ancestors matches the trail of the target branch over time,
    # This assumption is correct most of the time, especially for gitlab managed merges,
    # but there are exception cases which can't be solved.
    def mark_all_direct_ancestors(commit)
      loop do
        commit = get_commit(commit.parent_ids.first)

        break unless commit

        commit.direct_ancestor = true
      end
    end

    def get_commit(id)
      @id_to_commit[id]
    end
  end
end

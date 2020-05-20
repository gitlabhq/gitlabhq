# frozen_string_literal: true

module Resolvers
  class BranchCommitResolver < BaseResolver
    type Types::CommitType, null: true

    alias_method :branch, :object

    def resolve(**args)
      return unless branch

      commit = branch.dereferenced_target

      ::Commit.new(commit, context[:branch_project]) if commit
    end
  end
end

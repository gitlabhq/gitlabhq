# frozen_string_literal: true

module Resolvers
  class BranchCommitResolver < BaseResolver
    type Types::CommitType, null: true

    alias_method :branch, :object

    def resolve(**args)
      return unless branch

      commit = branch.dereferenced_target
      project = Project.find_by_full_path(commit.repository.gl_project_path)

      ::Commit.new(commit, project) if commit
    end
  end
end

# frozen_string_literal: true

module Gitlab
  module Git
    class OperationService
      BranchUpdate = Struct.new(:newrev, :repo_created, :branch_created) do
        alias_method :repo_created?, :repo_created
        alias_method :branch_created?, :branch_created

        def self.from_gitaly(branch_update)
          return if branch_update.nil?

          new(
            branch_update.commit_id,
            branch_update.repo_created,
            branch_update.branch_created
          )
        end
      end
    end
  end
end

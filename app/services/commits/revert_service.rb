# frozen_string_literal: true

module Commits
  class RevertService < ChangeService
    def create_commit!
      commit_change(:revert) do |message|
        repository.revert(current_user, @commit, @branch_name, message,
          start_project: @start_project, start_branch_name: @start_branch, dry_run: @dry_run
        )
      end
    end

    private

    def commit_message
      commit.revert_message(current_user)
    end
  end
end

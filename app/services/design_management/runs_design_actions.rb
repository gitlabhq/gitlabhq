# frozen_string_literal: true

module DesignManagement
  module RunsDesignActions
    NoActions = Class.new(StandardError)

    # This concern requires the following methods to be implemented:
    #   current_user, target_branch, repository, commit_message
    #
    # Before calling `run_actions`, you should ensure the repository exists, by
    # calling `repository.create_if_not_exists`.
    #
    # @raise [NoActions] if actions are empty
    # @return [DesignManagement::Version]
    def run_actions(actions, skip_system_notes: false)
      raise NoActions if actions.empty?

      sha = repository.commit_files(
        current_user,
        branch_name: target_branch,
        message: commit_message,
        actions: actions.map(&:gitaly_action)
      )

      DesignManagement::Version
        .create_for_designs(actions, sha, current_user)
        .tap { |version| post_process(version, skip_system_notes) }
    end

    private

    def post_process(version, skip_system_notes)
      version.run_after_commit_or_now do
        DesignManagement::NewVersionWorker.perform_async(id, skip_system_notes)
      end
    end
  end
end

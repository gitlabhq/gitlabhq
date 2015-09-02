module MergeRequests
  # MergeService class
  #
  # Do git merge and in case of success
  # mark merge request as merged and execute all hooks and notifications
  # Executed when you do merge via GitLab UI
  #
  class RebaseService < MergeRequests::BaseService
    include Gitlab::Popen

    attr_reader :merge_request

    def execute(merge_request)
      @merge_request = merge_request

      if rebase
        success
      else
        error('Failed to rebase. Should be done manually')
      end
    end

    def rebase
      Gitlab::ShellEnv.set_env(current_user)

      # Clone
      output, status = popen(%W(git clone -b #{merge_request.source_branch} -- #{source_project.repository.path_to_repo} #{tree_path}))
      raise 'Failed to clone repo' unless status.zero?

      # Rebase
      output, status = popen(%W(git pull --rebase #{target_project.repository.path_to_repo} #{merge_request.target_branch}), tree_path)
      raise 'Failed to rebase' unless status.zero?

      output, status = popen(%W(git push -f origin #{merge_request.source_branch}), tree_path)
      raise 'Failed to push' unless status.zero?

      true
    ensure
      Gitlab::ShellEnv.reset_env
    end

    def source_project
      @source_project ||= merge_request.source_project
    end

    def target_project
      @target_project ||= merge_request.target_project
    end

    def tree_path
      @tree_path ||= Rails.root.join('tmp', 'rebase', source_project.id.to_s, SecureRandom.hex).to_s
    end
  end
end

class PostReceive
  include Sidekiq::Worker
  include DedicatedSidekiqQueue

  def perform(repo_path, identifier, changes)
    repo_relative_path = Gitlab::RepoPath.strip_storage_path(repo_path)

    changes = Base64.decode64(changes) unless changes.include?(' ')
    # Use Sidekiq.logger so arguments can be correlated with execution
    # time and thread ID's.
    Sidekiq.logger.info "changes: #{changes.inspect}" if ENV['SIDEKIQ_LOG_ARGUMENTS']
    post_received = Gitlab::GitPostReceive.new(repo_relative_path, identifier, changes)

    if post_received.project.nil?
      log("Triggered hook for non-existing project with full path \"#{repo_relative_path}\"")
      return false
    end

    if post_received.wiki?
      # Nothing defined here yet.
    elsif post_received.regular_project?
      process_project_changes(post_received)
    else
      log("Triggered hook for unidentifiable repository type with full path \"#{repo_relative_path}\"")
      false
    end
  end

  def process_project_changes(post_received)
    post_received.changes.each do |change|
      oldrev, newrev, ref = change.strip.split(' ')

      @user ||= post_received.identify(newrev)

      unless @user
        log("Triggered hook for non-existing user \"#{post_received.identifier}\"")
        return false
      end

      if Gitlab::Git.tag_ref?(ref)
        GitTagPushService.new(post_received.project, @user, oldrev: oldrev, newrev: newrev, ref: ref).execute
      elsif Gitlab::Git.branch_ref?(ref)
        GitPushService.new(post_received.project, @user, oldrev: oldrev, newrev: newrev, ref: ref).execute
      end
    end
  end

  private

  def log(message)
    Gitlab::GitLogger.error("POST-RECEIVE: #{message}")
  end
end

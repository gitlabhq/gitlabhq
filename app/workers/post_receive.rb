class PostReceive
  include Sidekiq::Worker

  sidekiq_options queue: :post_receive

  def perform(repo_path, identifier, changes)
    if repo_path.start_with?(Gitlab.config.gitlab_shell.repos_path.to_s)
      repo_path.gsub!(Gitlab.config.gitlab_shell.repos_path.to_s, "")
    else
      log("Check gitlab.yml config for correct gitlab_shell.repos_path variable. \"#{Gitlab.config.gitlab_shell.repos_path}\" does not match \"#{repo_path}\"")
    end

    post_received = Gitlab::GitPostReceive.new(repo_path, identifier, changes)

    if post_received.project.nil?
      log("Triggered hook for non-existing project with full path \"#{repo_path} \"")
      return false
    end

    if post_received.wiki?
      # Nothing defined here yet.
    elsif post_received.regular_project?
      process_project_changes(post_received)
    else
      log("Triggered hook for unidentifiable repository type with full path \"#{repo_path} \"")
      false
    end
  end

  def process_project_changes(post_received)
    post_received.changes.each do |change|
      oldrev, newrev, ref = change.strip.split(' ')

      @user ||= post_received.identify(newrev)

      unless @user
        log("Triggered hook for non-existing user \"#{post_received.identifier} \"")
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

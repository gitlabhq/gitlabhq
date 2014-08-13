class PostReceive
  include Sidekiq::Worker
  include Gitlab::Identifier

  sidekiq_options queue: :post_receive

  def perform(repo_path, oldrev, newrev, ref, identifier)

    if repo_path.start_with?(Gitlab.config.gitlab_shell.repos_path.to_s)
      repo_path.gsub!(Gitlab.config.gitlab_shell.repos_path.to_s, "")
    else
      log("Check gitlab.yml config for correct gitlab_shell.repos_path variable. \"#{Gitlab.config.gitlab_shell.repos_path}\" does not match \"#{repo_path}\"")
    end

    repo_path.gsub!(/\.git$/, "")
    repo_path.gsub!(/^\//, "")

    project = Project.find_with_namespace(repo_path)

    if project.nil?
      log("Triggered hook for non-existing project with full path \"#{repo_path} \"")
      return false
    end

    user = identify(identifier, project, newrev)

    unless user
      log("Triggered hook for non-existing user \"#{identifier} \"")
      return false
    end

    if tag?(ref)
      GitTagPushService.new.execute(project, user, oldrev, newrev, ref)
    else
      GitPushService.new.execute(project, user, oldrev, newrev, ref)
    end
  end

  def log(message)
    Gitlab::GitLogger.error("POST-RECEIVE: #{message}")
  end

  private

  def tag?(ref)
    !!(/refs\/tags\/(.*)/.match(ref))
  end
end

class PostReceive
  include Sidekiq::Worker

  sidekiq_options queue: :post_receive

  def perform(repo_path, oldrev, newrev, ref, identifier)

    if repo_path.start_with?(Gitlab.config.gitlab_shell.repos_path.to_s)
      repo_path.gsub!(Gitlab.config.gitlab_shell.repos_path.to_s, "")
    else
      Gitlab::GitLogger.error("POST-RECEIVE: Check gitlab.yml config for correct gitlab_shell.repos_path variable. \"#{Gitlab.config.gitlab_shell.repos_path}\" does not match \"#{repo_path}\"")
    end

    repo_path.gsub!(/.git$/, "")
    repo_path.gsub!(/^\//, "")

    project = Project.find_with_namespace(repo_path)

    if project.nil?
      Gitlab::GitLogger.error("POST-RECEIVE: Triggered hook for non-existing project with full path \"#{repo_path} \"")
      return false
    end

    user = if identifier.blank?
             # Local push from gitlab
             email = project.repository.commit(newrev).author_email rescue nil
             User.find_by_email(email) if email

           elsif identifier =~ /\Auser-\d+\Z/
             # git push over http
             user_id = identifier.gsub("user-", "")
             User.find_by_id(user_id)

           elsif identifier =~ /\Akey-\d+\Z/
             # git push over ssh
             key_id = identifier.gsub("key-", "")
             Key.find_by_id(key_id).try(:user)
           end

    unless user
      Gitlab::GitLogger.error("POST-RECEIVE: Triggered hook for non-existing user \"#{identifier} \"")
      return false
    end

    GitPushService.new.execute(project, user, oldrev, newrev, ref)
  end
end

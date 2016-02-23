class PostReceive
  include Sidekiq::Worker
  include Gitlab::Identifier

  sidekiq_options queue: :post_receive

  def perform(repo_path, identifier, changes)
    if repo_path.start_with?(Gitlab.config.gitlab_shell.repos_path.to_s)
      repo_path.gsub!(Gitlab.config.gitlab_shell.repos_path.to_s, "")
    else
      log("Check gitlab.yml config for correct gitlab_shell.repos_path variable. \"#{Gitlab.config.gitlab_shell.repos_path}\" does not match \"#{repo_path}\"")
    end

    repo_path.gsub!(/\.git\z/, "")
    repo_path.gsub!(/\A\//, "")

    project = Project.find_with_namespace(repo_path)

    if project.nil?
      log("Triggered hook for non-existing project with full path \"#{repo_path} \"")
      return false
    end

    changes = Base64.decode64(changes) unless changes.include?(" ")
    changes = utf8_encode_changes(changes)
    changes = changes.lines

    changes.each do |change|
      oldrev, newrev, ref = change.strip.split(' ')

      @user ||= identify(identifier, project, newrev)

      unless @user
        log("Triggered hook for non-existing user \"#{identifier} \"")
        return false
      end

      if Gitlab::Git.tag_ref?(ref)
        GitTagPushService.new.execute(project, @user, oldrev, newrev, ref)
      else
        GitPushService.new(project, @user, oldrev: oldrev, newrev: newrev, ref: ref).execute
      end
    end
  end

  def utf8_encode_changes(changes)
    changes = changes.dup

    changes.force_encoding("UTF-8")
    return changes if changes.valid_encoding?

    # Convert non-UTF-8 branch/tag names to UTF-8 so they can be dumped as JSON.
    detection = CharlockHolmes::EncodingDetector.detect(changes)
    return changes unless detection && detection[:encoding]

    CharlockHolmes::Converter.convert(changes, detection[:encoding], 'UTF-8')
  end

  def log(message)
    Gitlab::GitLogger.error("POST-RECEIVE: #{message}")
  end
end

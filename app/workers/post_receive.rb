class PostReceive
  include Sidekiq::Worker
  include DedicatedSidekiqQueue

  def perform(project_identifier, identifier, changes)
    project, is_wiki = parse_project_identifier(project_identifier)

    if project.nil?
      log("Triggered hook for non-existing project with identifier \"#{project_identifier}\"")
      return false
    end

    changes = Base64.decode64(changes) unless changes.include?(' ')
    # Use Sidekiq.logger so arguments can be correlated with execution
    # time and thread ID's.
    Sidekiq.logger.info "changes: #{changes.inspect}" if ENV['SIDEKIQ_LOG_ARGUMENTS']
    post_received = Gitlab::GitPostReceive.new(project, identifier, changes)

    if is_wiki
      # Nothing defined here yet.
    else
      process_project_changes(post_received)
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

  def parse_project_identifier(project_identifier)
    if project_identifier.start_with?('/')
      Gitlab::RepoPath.parse(project_identifier)
    else
      Gitlab::GlRepository.parse(project_identifier)
    end
  end

  def log(message)
    Gitlab::GitLogger.error("POST-RECEIVE: #{message}")
  end
end

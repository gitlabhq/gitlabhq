# frozen_string_literal: true

class PostReceive
  include ApplicationWorker

  def perform(gl_repository, identifier, changes)
    project, is_wiki = Gitlab::GlRepository.parse(gl_repository)

    if project.nil?
      log("Triggered hook for non-existing project with gl_repository \"#{gl_repository}\"")
      return false
    end

    changes = Base64.decode64(changes) unless changes.include?(' ')
    # Use Sidekiq.logger so arguments can be correlated with execution
    # time and thread ID's.
    Sidekiq.logger.info "changes: #{changes.inspect}" if ENV['SIDEKIQ_LOG_ARGUMENTS']
    post_received = Gitlab::GitPostReceive.new(project, identifier, changes)

    if is_wiki
      process_wiki_changes(post_received)
    else
      process_project_changes(post_received)
    end
  end

  private

  def process_project_changes(post_received)
    changes = []
    refs = Set.new
    post_receive_jobs = []

    post_received.changes_refs do |oldrev, newrev, ref|
      @user ||= post_received.identify(newrev)

      unless @user
        log("Triggered hook for non-existing user \"#{post_received.identifier}\"")
        return false # rubocop:disable Cop/AvoidReturnFromBlocks
      end

      if post_receive_job = post_receive_push_kind(ref)
        post_receive_jobs << [post_receive_job, post_received.project.id, @user.id, oldrev, newrev, ref]
      end

      changes << Gitlab::DataBuilder::Repository.single_change(oldrev, newrev, ref)
      refs << ref
    end

    if post_receive_jobs.any?
      PostReceivePushWorker.bulk_perform_and_wait(post_receive_jobs, timeout: post_receive_jobs.count * PostReceivePushWorker::DEFAULT_TIMEOUT)
    end

    after_project_changes_hooks(post_received, @user, refs.to_a, changes)
  end

  def after_project_changes_hooks(post_received, user, refs, changes)
    hook_data = Gitlab::DataBuilder::Repository.update(post_received.project, user, changes, refs)
    SystemHooksService.new.execute_hooks(hook_data, :repository_update_hooks)
  end

  def process_wiki_changes(post_received)
    post_received.project.touch(:last_activity_at, :last_repository_updated_at)
  end

  def log(message)
    Gitlab::GitLogger.error("POST-RECEIVE: #{message}")
  end

  def post_receive_push_kind(ref)
    if Gitlab::Git.tag_ref?(ref)
      'GitTagPushService'.freeze
    elsif Gitlab::Git.branch_ref?(ref)
      'GitPushService'.freeze
    end
  end
end

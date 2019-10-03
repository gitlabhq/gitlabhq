# frozen_string_literal: true

class PostReceive
  include ApplicationWorker

  PIPELINE_PROCESS_LIMIT = 4

  def perform(gl_repository, identifier, changes, push_options = {})
    project, repo_type = Gitlab::GlRepository.parse(gl_repository)

    if project.nil?
      log("Triggered hook for non-existing project with gl_repository \"#{gl_repository}\"")
      return false
    end

    changes = Base64.decode64(changes) unless changes.include?(' ')
    # Use Sidekiq.logger so arguments can be correlated with execution
    # time and thread ID's.
    Sidekiq.logger.info "changes: #{changes.inspect}" if ENV['SIDEKIQ_LOG_ARGUMENTS']
    post_received = Gitlab::GitPostReceive.new(project, identifier, changes, push_options)

    if repo_type.wiki?
      process_wiki_changes(post_received)
    elsif repo_type.project?
      process_project_changes(post_received)
    else
      # Other repos don't have hooks for now
    end
  end

  private

  def identify_user(post_received)
    post_received.identify.tap do |user|
      log("Triggered hook for non-existing user \"#{post_received.identifier}\"") unless user
    end
  end

  def process_project_changes(post_received)
    user = identify_user(post_received)

    return false unless user

    project = post_received.project
    push_options = post_received.push_options
    changes = post_received.changes

    # We only need to expire certain caches once per push
    expire_caches(post_received, post_received.project.repository)
    enqueue_repository_cache_update(post_received)

    process_changes(Git::BranchPushService, project, user, push_options, changes.branch_changes)
    process_changes(Git::TagPushService, project, user, push_options, changes.tag_changes)
    update_remote_mirrors(post_received)
    after_project_changes_hooks(project, user, changes.refs, changes.repository_data)
  end

  # Expire the repository status, branch, and tag cache once per push.
  def expire_caches(post_received, repository)
    repository.expire_status_cache if repository.empty?
    repository.expire_branches_cache if post_received.includes_branches?
    repository.expire_caches_for_tags if post_received.includes_tags?
  end

  # Schedule an update for the repository size and commit count if necessary.
  def enqueue_repository_cache_update(post_received)
    stats_to_invalidate = [:repository_size]
    stats_to_invalidate << :commit_count if post_received.includes_default_branch?

    ProjectCacheWorker.perform_async(
      post_received.project.id,
      [],
      stats_to_invalidate,
      true
    )
  end

  def process_changes(service_class, project, user, push_options, changes)
    return if changes.empty?

    changes.each do |change|
      service_class.new(
        project,
        user,
        change: change,
        push_options: push_options,
        create_pipelines: change[:index] < PIPELINE_PROCESS_LIMIT || Feature.enabled?(:git_push_create_all_pipelines, project)
      ).execute
    end
  end

  def update_remote_mirrors(post_received)
    return unless post_received.includes_branches? || post_received.includes_tags?

    project = post_received.project
    return unless project.has_remote_mirror?

    project.mark_stuck_remote_mirrors_as_failed!
    project.update_remote_mirrors
  end

  def after_project_changes_hooks(project, user, refs, changes)
    repository_update_hook_data = Gitlab::DataBuilder::Repository.update(project, user, changes, refs)
    SystemHooksService.new.execute_hooks(repository_update_hook_data, :repository_update_hooks)
    Gitlab::UsageDataCounters::SourceCodeCounter.count(:pushes)
  end

  def process_wiki_changes(post_received)
    post_received.project.touch(:last_activity_at, :last_repository_updated_at)
    post_received.project.wiki.repository.expire_statistics_caches
    ProjectCacheWorker.perform_async(post_received.project.id, [], [:wiki_size])

    user = identify_user(post_received)
    return false unless user

    # We only need to expire certain caches once per push
    expire_caches(post_received, post_received.project.wiki.repository)

    ::Git::WikiPushService.new(post_received.project, user, changes: post_received.changes).execute
  end

  def log(message)
    Gitlab::GitLogger.error("POST-RECEIVE: #{message}")
  end
end

PostReceive.prepend_if_ee('EE::PostReceive')

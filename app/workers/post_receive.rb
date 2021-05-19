# frozen_string_literal: true

class PostReceive # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  sidekiq_options retry: 3
  include Gitlab::Experiment::Dsl

  feature_category :source_code_management
  urgency :high
  worker_resource_boundary :cpu
  weight 5
  loggable_arguments 0, 1, 2, 3

  def perform(gl_repository, identifier, changes, push_options = {})
    container, project, repo_type = Gitlab::GlRepository.parse(gl_repository)

    if container.nil? || (container.is_a?(ProjectSnippet) && project.nil?)
      log("Triggered hook for non-existing gl_repository \"#{gl_repository}\"")
      return false
    end

    changes = Base64.decode64(changes) unless changes.include?(' ')
    # Use Sidekiq.logger so arguments can be correlated with execution
    # time and thread ID's.
    Sidekiq.logger.info "changes: #{changes.inspect}" if SidekiqLogArguments.enabled?
    post_received = Gitlab::GitPostReceive.new(container, identifier, changes, push_options)

    if repo_type.wiki?
      process_wiki_changes(post_received, container)
    elsif repo_type.project?
      process_project_changes(post_received, container)
    elsif repo_type.snippet?
      process_snippet_changes(post_received, container)
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

  def process_project_changes(post_received, project)
    user = identify_user(post_received)

    return false unless user

    push_options = post_received.push_options
    changes = post_received.changes

    # We only need to expire certain caches once per push
    expire_caches(post_received, project.repository)
    enqueue_project_cache_update(post_received, project)

    process_ref_changes(project, user, push_options: push_options, changes: changes)
    update_remote_mirrors(post_received, project)
    after_project_changes_hooks(project, user, changes.refs, changes.repository_data)
  end

  def process_wiki_changes(post_received, wiki)
    user = identify_user(post_received)
    return false unless user

    # We only need to expire certain caches once per push
    expire_caches(post_received, wiki.repository)
    wiki.repository.expire_statistics_caches

    ::Git::WikiPushService.new(wiki, user, changes: post_received.changes).execute
  end

  def process_snippet_changes(post_received, snippet)
    user = identify_user(post_received)

    return false unless user

    replicate_snippet_changes(snippet)

    expire_caches(post_received, snippet.repository)
    Snippets::UpdateStatisticsService.new(snippet).execute
  end

  def replicate_snippet_changes(snippet)
    # Used by Gitlab Geo
  end

  # Expire the repository status, branch, and tag cache once per push.
  def expire_caches(post_received, repository)
    repository.expire_status_cache if repository.empty?
    repository.expire_branches_cache if post_received.includes_branches?
    repository.expire_caches_for_tags if post_received.includes_tags?
  end

  # Schedule an update for the repository size and commit count if necessary.
  def enqueue_project_cache_update(post_received, project)
    stats_to_invalidate = [:repository_size]
    stats_to_invalidate << :commit_count if post_received.includes_default_branch?

    ProjectCacheWorker.perform_async(
      project.id,
      [],
      stats_to_invalidate,
      true
    )
  end

  def process_ref_changes(project, user, params = {})
    return unless params[:changes].any?

    Git::ProcessRefChangesService.new(project, user, params).execute
  end

  def update_remote_mirrors(post_received, project)
    return unless post_received.includes_branches? || post_received.includes_tags?

    return unless project.has_remote_mirror?

    project.mark_stuck_remote_mirrors_as_failed!
    project.update_remote_mirrors
  end

  def after_project_changes_hooks(project, user, refs, changes)
    experiment(:new_project_readme, actor: user).track_initial_writes(project)
    experiment(:empty_repo_upload, project: project).track_initial_write
    repository_update_hook_data = Gitlab::DataBuilder::Repository.update(project, user, changes, refs)
    SystemHooksService.new.execute_hooks(repository_update_hook_data, :repository_update_hooks)
    Gitlab::UsageDataCounters::SourceCodeCounter.count(:pushes)
  end

  def log(message)
    Gitlab::GitLogger.error("POST-RECEIVE: #{message}")
  end
end

PostReceive.prepend_mod_with('PostReceive')

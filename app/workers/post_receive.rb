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

  def process_project_changes(post_received)
    changes = []
    refs = Set.new
    @user = post_received.identify

    unless @user
      log("Triggered hook for non-existing user \"#{post_received.identifier}\"")
      return false
    end

    post_received.enum_for(:changes_refs).with_index do |(oldrev, newrev, ref), index|
      service_klass =
        if Gitlab::Git.tag_ref?(ref)
          Git::TagPushService
        elsif Gitlab::Git.branch_ref?(ref)
          Git::BranchPushService
        end

      if service_klass
        service_klass.new(
          post_received.project,
          @user,
          oldrev: oldrev,
          newrev: newrev,
          ref: ref,
          push_options: post_received.push_options,
          create_pipelines: index < PIPELINE_PROCESS_LIMIT || Feature.enabled?(:git_push_create_all_pipelines, post_received.project)
        ).execute
      end

      changes << Gitlab::DataBuilder::Repository.single_change(oldrev, newrev, ref)
      refs << ref
    end

    after_project_changes_hooks(post_received, @user, refs.to_a, changes)
  end

  def after_project_changes_hooks(post_received, user, refs, changes)
    hook_data = Gitlab::DataBuilder::Repository.update(post_received.project, user, changes, refs)
    SystemHooksService.new.execute_hooks(hook_data, :repository_update_hooks)
  end

  def process_wiki_changes(post_received)
    post_received.project.touch(:last_activity_at, :last_repository_updated_at)
    post_received.project.wiki.repository.expire_statistics_caches
    ProjectCacheWorker.perform_async(post_received.project.id, [], [:wiki_size])
  end

  def log(message)
    Gitlab::GitLogger.error("POST-RECEIVE: #{message}")
  end
end

# frozen_string_literal: true

module Git
  class BaseHooksService < ::BaseService
    include Gitlab::Utils::StrongMemoize

    # The N most recent commits to process in a single push payload.
    PROCESS_COMMIT_LIMIT = 100

    def execute
      project.repository.after_create if project.empty_repo?

      create_events
      create_pipelines
      execute_project_hooks

      # Not a hook, but it needs access to the list of changed commits
      enqueue_invalidate_cache

      update_remote_mirrors

      push_data
    end

    private

    def hook_name
      raise NotImplementedError, "Please implement #{self.class}##{__method__}"
    end

    def commits
      raise NotImplementedError, "Please implement #{self.class}##{__method__}"
    end

    def limited_commits
      commits.last(PROCESS_COMMIT_LIMIT)
    end

    def commits_count
      commits.count
    end

    def event_message
      nil
    end

    def invalidated_file_types
      []
    end

    def create_events
      EventCreateService.new.push(project, current_user, push_data)
    end

    def create_pipelines
      return unless params.fetch(:create_pipelines, true)

      Ci::CreatePipelineService
        .new(project, current_user, push_data)
        .execute(:push, pipeline_options)
    end

    def execute_project_hooks
      project.execute_hooks(push_data, hook_name)
      project.execute_services(push_data, hook_name)
    end

    def enqueue_invalidate_cache
      ProjectCacheWorker.perform_async(
        project.id,
        invalidated_file_types,
        [:commit_count, :repository_size]
      )
    end

    def push_data
      @push_data ||= Gitlab::DataBuilder::Push.build(
        project: project,
        user: current_user,
        oldrev: params[:oldrev],
        newrev: params[:newrev],
        ref: params[:ref],
        commits: limited_commits,
        message: event_message,
        commits_count: commits_count,
        push_options: params[:push_options] || {}
      )

      # Dependent code may modify the push data, so return a duplicate each time
      @push_data.dup
    end

    # to be overridden in EE
    def pipeline_options
      {}
    end

    def update_remote_mirrors
      return unless project.has_remote_mirror?

      project.mark_stuck_remote_mirrors_as_failed!
      project.update_remote_mirrors
    end
  end
end

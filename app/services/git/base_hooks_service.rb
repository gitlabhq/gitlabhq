# frozen_string_literal: true

module Git
  class BaseHooksService < ::BaseService
    include Gitlab::Utils::StrongMemoize

    # The N most recent commits to process in a single push payload.
    PROCESS_COMMIT_LIMIT = 100

    def execute
      create_events
      create_pipelines
      execute_project_hooks

      # Not a hook, but it needs access to the list of changed commits
      enqueue_invalidate_cache

      update_remote_mirrors

      success
    end

    private

    def hook_name
      raise NotImplementedError, "Please implement #{self.class}##{__method__}"
    end

    def commits
      raise NotImplementedError, "Please implement #{self.class}##{__method__}"
    end

    def limited_commits
      @limited_commits ||= commits.last(PROCESS_COMMIT_LIMIT)
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

    # Push events in the activity feed only show information for the
    # last commit.
    def create_events
      EventCreateService.new.push(project, current_user, event_push_data)
    end

    def create_pipelines
      return unless params.fetch(:create_pipelines, true)

      Ci::CreatePipelineService
        .new(project, current_user, pipeline_params)
        .execute(:push, pipeline_options)
    end

    def execute_project_hooks
      # Creating push_data invokes one CommitDelta RPC per commit. Only
      # build this data if we actually need it.
      project.execute_hooks(push_data, hook_name) if project.has_active_hooks?(hook_name)
      project.execute_services(push_data, hook_name) if project.has_active_services?(hook_name)
    end

    def enqueue_invalidate_cache
      file_types = invalidated_file_types

      return unless file_types.present?

      ProjectCacheWorker.perform_async(project.id, file_types, [], false)
    end

    def pipeline_params
      {
        before: params[:oldrev],
        after: params[:newrev],
        ref: params[:ref],
        push_options: params[:push_options] || {},
        checkout_sha: Gitlab::DataBuilder::Push.checkout_sha(
          project.repository, params[:newrev], params[:ref])
      }
    end

    def push_data_params(commits:, with_changed_files: true)
      {
        oldrev: params[:oldrev],
        newrev: params[:newrev],
        ref: params[:ref],
        project: project,
        user: current_user,
        commits: commits,
        message: event_message,
        commits_count: commits_count,
        with_changed_files: with_changed_files
      }
    end

    def event_push_data
      # We only need the last commit for the event push, and we don't
      # need the full deltas either.
      @event_push_data ||= Gitlab::DataBuilder::Push.build(
        push_data_params(commits: commits.last, with_changed_files: false))
    end

    def push_data
      @push_data ||= Gitlab::DataBuilder::Push.build(push_data_params(commits: limited_commits))

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

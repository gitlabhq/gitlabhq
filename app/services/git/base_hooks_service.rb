# frozen_string_literal: true

module Git
  class BaseHooksService < ::BaseService
    include Gitlab::Utils::StrongMemoize
    include ChangeParams

    # The N most recent commits to process in a single push payload.
    PROCESS_COMMIT_LIMIT = 100

    def execute
      create_events
      create_pipelines
      execute_project_hooks

      # Not a hook, but it needs access to the list of changed commits
      enqueue_invalidate_cache
      enqueue_notify_kas

      success
    end

    private

    def hook_name
      raise NotImplementedError, "Please implement #{self.class}##{__method__}"
    end

    # This should return PROCESS_COMMIT_LIMIT commits, ordered with newest last
    def limited_commits
      raise NotImplementedError, "Please implement #{self.class}##{__method__}"
    end

    def commits_count
      raise NotImplementedError, "Please implement #{self.class}##{__method__}"
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
      return unless params.fetch(:create_push_event, true)

      EventCreateService.new.push(project, current_user, event_push_data)
    end

    def removing_ref?
      Gitlab::Git.blank_ref?(newrev)
    end

    def create_pipelines
      return unless params.fetch(:create_pipelines, true)
      return if removing_ref?

      response = Ci::CreatePipelineService
          .new(project, current_user, pipeline_params)
          .execute(:push, **pipeline_options)

      log_pipeline_errors(response.message) unless response.payload.persisted?
    end

    def execute_project_hooks
      return unless params.fetch(:execute_project_hooks, true)

      # Creating push_data invokes one CommitDelta RPC per commit. Only
      # build this data if we actually need it.
      project.execute_hooks(push_data, hook_name) if project.has_active_hooks?(hook_name)

      return unless project.has_active_integrations?(hook_name)

      project.execute_integrations(push_data, hook_name, skip_ci: integration_push_options&.fetch(:skip_ci).present?)
    end

    def enqueue_invalidate_cache
      file_types = invalidated_file_types

      return unless file_types.present?

      ProjectCacheWorker.perform_async(project.id, file_types.map(&:to_s), [], false)
    end

    def enqueue_notify_kas
      return unless Gitlab::Kas.enabled?

      Clusters::Agents::NotifyGitPushWorker.perform_async(project.id)
    end

    def pipeline_params
      strong_memoize(:pipeline_params) do
        {
          before: oldrev,
          after: newrev,
          ref: ref,
          variables_attributes: generate_vars_from_push_options || [],
          push_options: params[:push_options] || {},
          checkout_sha: Gitlab::DataBuilder::Push.checkout_sha(
            project.repository, newrev, ref)
        }
      end
    end

    def ci_variables_from_push_options
      strong_memoize(:ci_variables_from_push_options) do
        push_options&.dig(:ci, :variable)
      end
    end

    def integration_push_options
      strong_memoize(:integration_push_options) do
        push_options&.dig(:integrations)
      end
    end

    def push_options
      strong_memoize(:push_options) do
        params[:push_options]&.deep_symbolize_keys
      end
    end

    def generate_vars_from_push_options
      return [] unless ci_variables_from_push_options

      ci_variables_from_push_options.map do |var_definition, _count|
        key, value = var_definition.to_s.split("=", 2)

        # Accept only valid format. We ignore the following formats
        # 1. "=123". In this case, `key` will be an empty string
        # 2. "FOO". In this case, `value` will be nil.
        # However, the format "FOO=" will result in key beign `FOO` and value
        # being an empty string. This is acceptable.
        next if key.blank? || value.nil?

        { "key" => key, "variable_type" => "env_var", "secret_value" => value }
      end.compact
    end

    def push_data_params(commits:, with_changed_files: true)
      {
        oldrev: oldrev,
        newrev: newrev,
        ref: ref,
        project: project,
        user: current_user,
        commits: commits,
        message: event_message,
        commits_count: commits_count,
        with_changed_files: with_changed_files
      }
    end

    def event_push_data
      # We only need the newest commit for the event push, and we don't
      # need the full deltas either.
      @event_push_data ||= Gitlab::DataBuilder::Push.build(
        **push_data_params(commits: limited_commits.last, with_changed_files: false)
      )
    end

    def push_data
      @push_data ||= Gitlab::DataBuilder::Push.build(**push_data_params(commits: limited_commits))

      # Dependent code may modify the push data, so return a duplicate each time
      @push_data.dup
    end

    # to be overridden in EE
    def pipeline_options
      {}
    end

    def log_pipeline_errors(error_message)
      data = {
        class: self.class.name,
        correlation_id: Labkit::Correlation::CorrelationId.current_id.to_s,
        project_id: project.id,
        project_path: project.full_path,
        message: "Error creating pipeline",
        errors: error_message,
        pipeline_params: sanitized_pipeline_params
      }

      logger.warn(data)
    end

    def sanitized_pipeline_params
      pipeline_params.except(:push_options)
    end

    def logger
      if Gitlab::Runtime.sidekiq?
        Sidekiq.logger
      else
        # This service runs in Sidekiq, so this shouldn't ever be
        # called, but this is included just in case.
        Gitlab::IntegrationsLogger
      end
    end
  end
end

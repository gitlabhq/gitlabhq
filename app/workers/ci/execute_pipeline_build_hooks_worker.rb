# frozen_string_literal: true

module Ci
  class ExecutePipelineBuildHooksWorker
    include ApplicationWorker

    data_consistency :delayed
    defer_on_database_health_signal :gitlab_ci, [:p_ci_builds], 1.minute

    feature_category :pipeline_composition
    urgency :low

    idempotent!

    def perform(pipeline_id)
      pipeline = Ci::Pipeline.find_by_id(pipeline_id)
      return unless pipeline&.project

      project = pipeline.project
      hooks = project.has_active_hooks?(:job_hooks)
      integrations = project.has_active_integrations?(:job_hooks)
      return unless hooks || integrations

      retries_counts = pipeline.builds.retried.group(:name).count # rubocop:disable CodeReuse/ActiveRecord -- One count for the whole pipeline instead of one per build

      pipeline.builds.includes(:project, :user, :ci_stage).find_each do |build| # rubocop:disable CodeReuse/ActiveRecord -- Preloading to prevent N+1 queries
        next if build.user&.blocked?

        data = build_created_hook_data(build, retries_counts.fetch(build.name, 0))

        project.execute_hooks(data.dup, :job_hooks) if hooks
        project.execute_integrations(data.dup, :job_hooks) if integrations
      end
    end

    private

    def build_created_hook_data(build, retries_count)
      data = Gitlab::DataBuilder::Build.build(build, retries_count: retries_count)

      data['build_status'] = 'created'
      data['build_started_at'] = nil
      data['build_finished_at'] = nil
      data['build_started_at_iso'] = nil
      data['build_finished_at_iso'] = nil
      data['build_duration'] = nil
      data['build_queued_duration'] = nil
      data['build_failure_reason'] = nil
      data['runner'] = nil

      data
    end
  end
end

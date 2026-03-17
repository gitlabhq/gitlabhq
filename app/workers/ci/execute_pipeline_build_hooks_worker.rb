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
      return unless pipeline

      builds = pipeline.builds.includes(:project, :user, :ci_stage) # rubocop:disable CodeReuse/ActiveRecord -- Preloading to prevent N+1 queries

      builds.each do |build|
        execute_hooks_for_created_build(build)
      end
    end

    private

    def execute_hooks_for_created_build(build)
      project = build.project
      return unless project
      return if build.user&.blocked?

      data = build_created_hook_data(build)

      project.execute_hooks(data.dup, :job_hooks) if project.has_active_hooks?(:job_hooks)
      project.execute_integrations(data.dup, :job_hooks) if project.has_active_integrations?(:job_hooks)
    end

    def build_created_hook_data(build)
      data = Gitlab::DataBuilder::Build.build(build)

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

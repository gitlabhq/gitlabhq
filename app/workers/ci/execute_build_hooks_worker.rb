# frozen_string_literal: true

module Ci
  class ExecuteBuildHooksWorker
    include ApplicationWorker

    data_consistency :delayed

    feature_category :pipeline_composition
    urgency :low

    idempotent!

    def perform(project_id, build_data)
      project = Project.find_by_id(project_id)
      return unless project

      project.execute_hooks(build_data, :job_hooks) if project.has_active_hooks?(:job_hooks)
      project.execute_integrations(build_data, :job_hooks) if project.has_active_integrations?(:job_hooks)
    end
  end
end

# frozen_string_literal: true

module Observability
  class PipelinesSinceSetupExist
    # 10k MAX_PLUCK is acceptable here because callers always invoke .exists?
    # (LIMIT 1) and the (project_id, status, created_at) index keeps the plan
    # bounded. Order is non-deterministic; that's fine for an existence check.
    MAX_PROJECTS = 10_000

    # namespace - a Group or personal (user) Namespace.
    def initialize(namespace)
      @namespace = namespace
    end

    def execute
      setting = @namespace.observability_group_o11y_setting
      return false unless setting

      project_ids = active_project_ids
      return false if project_ids.empty?

      Ci::Pipeline
        .for_project(project_ids)
        .ci_sources
        .for_status(%i[success failed])
        .created_after(setting.created_at)
        .finished_after(setting.created_at)
        .exists?
    end

    private

    def active_project_ids
      @namespace.all_active_project_ids.limit(MAX_PROJECTS).pluck(:id) # rubocop:disable CodeReuse/ActiveRecord -- pluck avoids cross-join with CI schema
    end
  end
end

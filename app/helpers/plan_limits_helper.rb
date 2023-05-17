# frozen_string_literal: true

module PlanLimitsHelper
  def plan_limit_setting_description(limit_name)
    case limit_name
    when :ci_pipeline_size
      s_('AdminSettings|Maximum number of jobs in a single pipeline')
    when :ci_active_jobs
      s_('AdminSettings|Total number of jobs in currently active pipelines')
    when :ci_project_subscriptions
      s_('AdminSettings|Maximum number of pipeline subscriptions to and from a project')
    when :ci_pipeline_schedules
      s_('AdminSettings|Maximum number of pipeline schedules')
    when :ci_needs_size_limit
      s_('AdminSettings|Maximum number of DAG dependencies that a job can have')
    when :ci_registered_group_runners
      s_('AdminSettings|Maximum number of runners registered per group')
    when :ci_registered_project_runners
      s_('AdminSettings|Maximum number of runners registered per project')
    when :pipeline_hierarchy_size
      s_("AdminSettings|Maximum number of downstream pipelines in a pipeline's hierarchy tree")
    else
      raise ArgumentError, "No description available for plan limit #{limit_name}"
    end
  end
end

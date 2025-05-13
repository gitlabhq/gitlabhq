# frozen_string_literal: true

module Ci
  module PipelineSchedulesHelper
    def js_pipeline_schedules_form_data(project, schedule)
      {
        can_view_pipeline_editor: can_view_pipeline_editor?(project).to_s,
        daily_limit: schedule.daily_limit,
        default_branch: project.default_branch,
        pipeline_editor_path: project_ci_pipeline_editor_path(project),
        project_id: project.id,
        project_path: project.full_path,
        schedules_path: pipeline_schedules_path(project),
        settings_link: project_settings_ci_cd_path(project),
        timezone_data: timezone_data.to_json,
        can_set_pipeline_variables: Ability.allowed?(current_user, :set_pipeline_variables, project).to_s
      }
    end
  end
end

Ci::PipelineSchedulesHelper.prepend_mod_with('Ci::PipelineSchedulesHelper')

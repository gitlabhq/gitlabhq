# frozen_string_literal: true

module Ci
  module PipelineSchedulesHelper
    def js_pipeline_schedules_form_data(project, schedule)
      {
        full_path: project.full_path,
        daily_limit: schedule.daily_limit,
        timezone_data: timezone_data.to_json,
        project_id: project.id,
        default_branch: project.default_branch,
        settings_link: project_settings_ci_cd_path(project),
        schedules_path: pipeline_schedules_path(project)
      }
    end
  end
end

Ci::PipelineSchedulesHelper.prepend_mod_with('Ci::PipelineSchedulesHelper')

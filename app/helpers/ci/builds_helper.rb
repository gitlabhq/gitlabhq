# frozen_string_literal: true

module Ci
  module BuildsHelper
    def sidebar_build_class(build, current_build)
      build_class = []
      build_class << 'active' if build.id === current_build.id
      build_class << 'retried' if build.retried?
      build_class.join(' ')
    end

    def javascript_build_options
      {
        page_path: project_job_path(@project, @build),
        build_status: @build.status,
        build_stage: @build.stage_name,
        log_state: ''
      }
    end

    def build_failed_issue_options
      {
        title: _("Job Failed #%{build_id}") % { build_id: @build.id },
        description: project_job_url(@project, @build)
      }
    end
  end
end

# frozen_string_literal: true

module Ci
  module BuildsHelper
    def build_failed_issue_options
      {
        title: _("Job Failed #%{build_id}") % { build_id: @build.id },
        description: project_job_url(@project, @build)
      }
    end
  end
end

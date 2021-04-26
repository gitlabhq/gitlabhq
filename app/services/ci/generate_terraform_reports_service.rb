# frozen_string_literal: true

module Ci
  # TODO: a couple of points with this approach:
  # + reuses existing architecture and reactive caching
  # - it's not a report comparison and some comparing features must be turned off.
  # see CompareReportsBaseService for more notes.
  # issue: https://gitlab.com/gitlab-org/gitlab/issues/34224
  class GenerateTerraformReportsService < CompareReportsBaseService
    def execute(base_pipeline, head_pipeline)
      {
        status: :parsed,
        key: key(base_pipeline, head_pipeline),
        data: head_pipeline.terraform_reports.plans
      }
    rescue StandardError => e
      Gitlab::ErrorTracking.track_exception(e, project_id: project.id)
      {
        status: :error,
        key: key(base_pipeline, head_pipeline),
        status_reason: _('An error occurred while fetching terraform reports.')
      }
    end

    def latest?(base_pipeline, head_pipeline, data)
      data&.fetch(:key, nil) == key(base_pipeline, head_pipeline)
    end
  end
end

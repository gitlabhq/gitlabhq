# frozen_string_literal: true

module Ci
  # TODO: a couple of points with this approach:
  # + reuses existing architecture and reactive caching
  # - it's not a report comparison and some comparing features must be turned off.
  # see CompareReportsBaseService for more notes.
  # issue: https://gitlab.com/gitlab-org/gitlab/issues/34224
  class GenerateCoverageReportsService < CompareReportsBaseService
    def execute(base_pipeline, head_pipeline)
      merge_request = MergeRequest.find_by_id(params[:id])
      code_coverage_artifact = head_pipeline.pipeline_artifacts.find_by_file_type(:code_coverage)
      return error_response(base_pipeline, head_pipeline) unless code_coverage_artifact && merge_request

      {
        status: :parsed,
        key: key(base_pipeline, head_pipeline),
        data: code_coverage_artifact.present.for_files(merge_request.new_paths)
      }
    rescue StandardError => e
      track_exception(e, base_pipeline, head_pipeline)
      error_response(base_pipeline, head_pipeline)
    end

    def latest?(base_pipeline, head_pipeline, data)
      data&.fetch(:key, nil) == key(base_pipeline, head_pipeline)
    end

    private

    def error_response(base_pipeline, head_pipeline)
      {
        status: :error,
        key: key(base_pipeline, head_pipeline),
        status_reason: _('An error occurred while fetching coverage reports.')
      }
    end

    def track_exception(error, base_pipeline, head_pipeline)
      Gitlab::ErrorTracking.track_exception(
        error,
        project_id: project.id,
        base_pipeline_id: base_pipeline&.id,
        head_pipeline_id: head_pipeline&.id
      )
    end

    def key(base_pipeline, head_pipeline)
      [
        base_pipeline&.id, last_update_timestamp(base_pipeline),
        head_pipeline&.id, last_update_timestamp(head_pipeline)
      ]
    end

    def last_update_timestamp(pipeline_hierarchy)
      pipeline_hierarchy&.self_and_project_descendants&.maximum(:updated_at)
    end
  end
end

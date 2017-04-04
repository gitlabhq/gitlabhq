class MergeRequestPresenter < Gitlab::View::Presenter::Delegated
  presents :merge_request

  def ci_status
    pipeline = merge_request.head_pipeline

    if pipeline
      status = pipeline.status
      status = "success_with_warnings" if pipeline.success? && pipeline.has_warnings?

      status || "preparing"
    else
      ci_service = merge_request.source_project.try(:ci_service)
      ci_service&.commit_status(merge_request.diff_head_sha, merge_request.source_branch)
    end
  end
end

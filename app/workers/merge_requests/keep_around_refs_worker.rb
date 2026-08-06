# frozen_string_literal: true

module MergeRequests
  class KeepAroundRefsWorker
    include ApplicationWorker

    data_consistency :sticky

    sidekiq_options retry: 20

    feature_category :code_review_workflow
    urgency :high
    defer_on_database_health_signal :gitlab_main, [:none], 1.minute
    idempotent!

    # A single merge saves the merge request several times with `merge_commit_sha`
    # already set, so `MergeRequest#enqueue_keep_around_commit` fans out multiple
    # jobs with identical arguments. Writing the same keep-around ref concurrently
    # races in Praefect's reference transactions, which can leave orphaned ref
    # lockfiles behind. See https://gitlab.com/gitlab-org/gitlab/-/issues/608179.
    deduplicate :until_executed

    def perform(project_ids, shas, source)
      project_ids = Array(project_ids).compact
      shas = Array(shas).compact

      unless project_ids.present? && shas.present?
        logger.info(structured_payload(
          message: 'Missing required parameters.',
          project_ids: project_ids,
          shas: shas
        ))
        return
      end

      MergeRequests::KeepAroundRefsService.new(
        project_ids: project_ids,
        shas: shas,
        source: source
      ).execute
    end
  end
end

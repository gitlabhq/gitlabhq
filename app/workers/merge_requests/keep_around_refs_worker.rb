# frozen_string_literal: true

module MergeRequests
  class KeepAroundRefsWorker
    include ApplicationWorker

    # Inheriting `RetryError` keeps the retry out of Sentry and out of the Sidekiq
    # execution SLI: `Gitlab::Git::KeepAround` has already tracked the underlying
    # Gitaly error, so it is reported once, at its real source.
    KeepAroundRefsError = Class.new(::Gitlab::SidekiqMiddleware::RetryError)

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

      response = MergeRequests::KeepAroundRefsService.new(
        project_ids: project_ids,
        shas: shas,
        source: source
      ).execute

      # Only a project with `retry_failed_keep_around_ref_writes` enabled produces a
      # `ServiceResponse`; a fully disabled job keeps the service's old return value,
      # whatever it is. The type check goes away with the flag.
      return unless response.is_a?(ServiceResponse) && response.error?

      unwritten_shas = response.payload[:unwritten_shas]

      # Job-level summary only: the service has already logged each SHA with its cause
      # and its repository, which is the only place it can be attributed to one.
      logger.warn(structured_payload(
        message: 'Keep-around references were not written.',
        project_ids: project_ids,
        shas: unwritten_shas
      ))

      # Unlike the inline callers `Gitlab::Git::KeepAround` protects by swallowing the
      # error, this worker can afford to fail, and has to: an unwritten ref leaves the
      # commit unprotected from `git gc`, and only a retry will still write it.
      raise KeepAroundRefsError, response.message
    end
  end
end

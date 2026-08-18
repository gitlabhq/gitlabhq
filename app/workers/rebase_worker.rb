# frozen_string_literal: true

# The RebaseWorker must be wrapped in important concurrency code, so should only
# be scheduled via MergeRequest#rebase_async
class RebaseWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3

  feature_category :source_code_management
  weight 2
  loggable_arguments 2

  # Rebase failure reasons that represent an expected user outcome (merge
  # conflicts, push rules, a missing source branch) rather than a
  # system/infrastructure failure. These must not count against the
  # ui_button_rebase UX SLI error rate; a handled-but-slow rebase still feeds
  # apdex so latency regressions remain visible.
  EXPECTED_REBASE_FAILURES = [
    MergeRequests::RebaseService::REASON_CONFLICT,
    MergeRequests::RebaseService::REASON_SOURCE_BRANCH_MISSING,
    MergeRequests::RebaseService::REASON_PRE_RECEIVE
  ].freeze

  def perform(merge_request_id, current_user_id, skip_ci = false)
    # On the REST API and /rebase quick action paths the experience is never
    # started, and Labkit short-circuits resume/complete on an unstarted
    # experience, so this only measures the web UI button journey.
    xp = Labkit::UserExperienceSli.resume(:ui_button_rebase)

    current_user = User.find(current_user_id)
    merge_request = MergeRequest.find(merge_request_id)

    result = MergeRequests::RebaseService
      .new(project: merge_request.source_project, current_user: current_user)
      .execute(merge_request, skip_ci: skip_ci)

    xp.error!(result.message) if rebase_failed_unexpectedly?(result)

    result
  rescue StandardError => e
    xp.error!(e.message)
    raise
  ensure
    # Record the outcome as a custom SLI log dimension so analytics can tell a
    # successful rebase apart from a handled conflict (both complete without an
    # SLI error) without having to inflate the error rate.
    xp.complete(rebase_result: rebase_outcome(result))
  end

  private

  def rebase_failed_unexpectedly?(result)
    result.error? && EXPECTED_REBASE_FAILURES.exclude?(result.reason)
  end

  # `result` is nil when an exception aborted the job before the service
  # returned; that path already flags an SLI error, so record it as :error
  # rather than mislabelling it a success.
  def rebase_outcome(result)
    return :error unless result

    result.reason || :success
  end
end

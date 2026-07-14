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

    xp.error!(result[:message]) unless result[:status] == :success

    result
  rescue StandardError => e
    xp.error!(e.message)
    raise
  ensure
    xp.complete
  end
end

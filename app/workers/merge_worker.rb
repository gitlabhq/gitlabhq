# frozen_string_literal: true

class MergeWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3

  feature_category :code_review_workflow
  urgency :high
  weight 5
  loggable_arguments 2
  idempotent!

  deduplicate :until_executed, including_scheduled: true

  def perform(merge_request_id, current_user_id, params)
    # MergeService enqueues downstream jobs that reset the per-thread experience
    # context, so the reference must be captured up front. On the GraphQL and
    # auto-merge paths the experience is never started, and Labkit short-circuits
    # resume/complete on an unstarted experience.
    experience = Labkit::UserExperienceSli.resume(:immediate_web_merge)

    Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/464676')

    begin
      current_user = User.find(current_user_id)
      merge_request = MergeRequest.find(merge_request_id)
    rescue ActiveRecord::RecordNotFound
      experience.error!('merge request or user not found').complete
      return
    end

    params = params.with_indifferent_access
    params[:check_mergeability_retry_lease] = true unless params.has_key?(:check_mergeability_retry_lease)

    MergeRequests::MergeService.new(project: merge_request.target_project, current_user: current_user, params: params)
      .execute(merge_request)

    experience.error!(merge_request.merge_error) unless merge_request.merged?
    experience.complete
  end
end

MergeWorker.prepend_mod

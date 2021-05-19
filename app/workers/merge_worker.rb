# frozen_string_literal: true

class MergeWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  sidekiq_options retry: 3

  feature_category :source_code_management
  urgency :high
  weight 5
  loggable_arguments 2
  idempotent!

  deduplicate :until_executed, including_scheduled: true

  def perform(merge_request_id, current_user_id, params)
    params = params.with_indifferent_access

    begin
      current_user = User.find(current_user_id)
      merge_request = MergeRequest.find(merge_request_id)
    rescue ActiveRecord::RecordNotFound
      return
    end

    MergeRequests::MergeService.new(project: merge_request.target_project, current_user: current_user, params: params)
      .execute(merge_request)
  end
end

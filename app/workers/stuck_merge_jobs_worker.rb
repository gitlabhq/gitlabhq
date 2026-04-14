# frozen_string_literal: true

class StuckMergeJobsWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

  feature_category :code_review_workflow

  def perform
    MergeRequests::UnstickLockedMergeRequestsService.new.execute
  end
end

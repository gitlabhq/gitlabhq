# frozen_string_literal: true

# Worker that deletes a fixed number of outdated rows from the "web_hook_logs"
# table.
class PruneWebHookLogsWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  sidekiq_options retry: 3
  # rubocop:disable Scalability/CronWorkerContext
  # This worker does not perform work scoped to a context
  include CronjobQueue
  # rubocop:enable Scalability/CronWorkerContext

  feature_category :integrations

  # The maximum number of rows to remove in a single job.
  DELETE_LIMIT = 50_000

  def perform
    cutoff_date = 90.days.ago.beginning_of_day

    WebHookLog.created_before(cutoff_date).delete_with_limit(DELETE_LIMIT)
  end
end

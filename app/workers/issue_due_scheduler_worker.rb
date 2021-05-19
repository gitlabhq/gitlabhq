# frozen_string_literal: true

class IssueDueSchedulerWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  sidekiq_options retry: 3
  include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

  feature_category :issue_tracking

  # rubocop: disable CodeReuse/ActiveRecord
  def perform
    project_ids = Issue.opened.due_tomorrow.group(:project_id).pluck(:project_id).map { |id| [id] }

    MailScheduler::IssueDueWorker.bulk_perform_async(project_ids) # rubocop:disable Scalability/BulkPerformWithContext
  end
  # rubocop: enable CodeReuse/ActiveRecord
end

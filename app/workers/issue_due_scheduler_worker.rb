# frozen_string_literal: true

class IssueDueSchedulerWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

  feature_category :team_planning

  # rubocop: disable CodeReuse/ActiveRecord
  def perform
    project_ids = Issue
      .with_issue_type(:issue)
      .opened
      .due_tomorrow
      .group(:project_id)
      .pluck(:project_id)
      .map { |id| [id] }

    MailScheduler::IssueDueWorker.bulk_perform_async(project_ids) # rubocop:disable Scalability/BulkPerformWithContext
  end
  # rubocop: enable CodeReuse/ActiveRecord
end

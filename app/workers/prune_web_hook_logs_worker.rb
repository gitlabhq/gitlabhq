# frozen_string_literal: true

# Worker that deletes a fixed number of outdated rows from the "web_hook_logs"
# table.
class PruneWebHookLogsWorker
  include ApplicationWorker
  include CronjobQueue

  # The maximum number of rows to remove in a single job.
  DELETE_LIMIT = 50_000

  # rubocop: disable CodeReuse/ActiveRecord
  def perform
    # MySQL doesn't allow "DELETE FROM ... WHERE id IN ( ... )" if the inner
    # query refers to the same table. To work around this we wrap the IN body in
    # another sub query.
    WebHookLog
      .where(
        'id IN (SELECT id FROM (?) ids_to_remove)',
        WebHookLog
          .select(:id)
          .where('created_at < ?', 90.days.ago.beginning_of_day)
          .limit(DELETE_LIMIT)
      )
      .delete_all
  end
  # rubocop: enable CodeReuse/ActiveRecord
end

# frozen_string_literal: false

class ScheduleMigrateExternalDiffsWorker
  include ApplicationWorker
  include CronjobQueue
  include Gitlab::ExclusiveLeaseHelpers

  def perform
    in_lock(self.class.name.underscore, ttl: 2.hours, retries: 0) do
      MergeRequests::MigrateExternalDiffsService.enqueue!
    end
  rescue Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError
  end
end

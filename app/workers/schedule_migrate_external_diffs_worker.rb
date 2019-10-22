# frozen_string_literal: true

class ScheduleMigrateExternalDiffsWorker
  include ApplicationWorker
  include CronjobQueue
  include Gitlab::ExclusiveLeaseHelpers

  feature_category :source_code_management

  def perform
    in_lock(self.class.name.underscore, ttl: 2.hours, retries: 0) do
      MergeRequests::MigrateExternalDiffsService.enqueue!
    end
  rescue Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError
  end
end

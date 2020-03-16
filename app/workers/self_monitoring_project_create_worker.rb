# frozen_string_literal: true

class SelfMonitoringProjectCreateWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker
  include ExclusiveLeaseGuard
  include SelfMonitoringProjectWorker

  def perform
    try_obtain_lease do
      Gitlab::DatabaseImporters::SelfMonitoring::Project::CreateService.new.execute
    end
  end
end

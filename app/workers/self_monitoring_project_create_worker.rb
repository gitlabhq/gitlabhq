# frozen_string_literal: true

class SelfMonitoringProjectCreateWorker
  include ApplicationWorker
  include ExclusiveLeaseGuard

  # This worker falls under Self-monitoring with Monitor::APM group. However,
  # self-monitoring is not classified as a feature category but rather as
  # Other Functionality. Metrics seems to be the closest feature_category for
  # this worker.
  feature_category :metrics

  LEASE_TIMEOUT = 15.minutes.to_i

  EXCLUSIVE_LEASE_KEY = 'self_monitoring_service_creation_deletion'

  def perform
    try_obtain_lease do
      Gitlab::DatabaseImporters::SelfMonitoring::Project::CreateService.new.execute
    end
  end

  # @param job_id [String]
  #   Job ID that is used to construct the cache keys.
  # @return [Hash]
  #   Returns true if the job is enqueued or in progress and false otherwise.
  def self.in_progress?(job_id)
    Gitlab::SidekiqStatus.job_status(Array.wrap(job_id)).first
  end

  private

  def lease_key
    EXCLUSIVE_LEASE_KEY
  end

  def lease_timeout
    LEASE_TIMEOUT
  end
end

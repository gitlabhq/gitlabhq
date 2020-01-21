# frozen_string_literal: true

module SelfMonitoringProjectWorker
  extend ActiveSupport::Concern

  included do
    # This worker falls under Self-monitoring with Monitor::APM group. However,
    # self-monitoring is not classified as a feature category but rather as
    # Other Functionality. Metrics seems to be the closest feature_category for
    # this worker.
    feature_category :metrics
  end

  LEASE_TIMEOUT = 15.minutes.to_i
  EXCLUSIVE_LEASE_KEY = 'self_monitoring_service_creation_deletion'

  class_methods do
    # @param job_id [String]
    #   Job ID that is used to construct the cache keys.
    # @return [Hash]
    #   Returns true if the job is enqueued or in progress and false otherwise.
    def in_progress?(job_id)
      Gitlab::SidekiqStatus.job_status(Array.wrap(job_id)).first
    end
  end

  private

  def lease_key
    EXCLUSIVE_LEASE_KEY
  end

  def lease_timeout
    self.class::LEASE_TIMEOUT
  end
end

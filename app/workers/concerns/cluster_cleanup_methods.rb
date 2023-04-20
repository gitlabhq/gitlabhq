# frozen_string_literal: true

# Concern for setting Sidekiq settings for the various GitLab ObjectStorage workers.
module ClusterCleanupMethods
  extend ActiveSupport::Concern

  include ApplicationWorker
  include ClusterQueue

  DEFAULT_EXECUTION_LIMIT = 10
  ExceededExecutionLimitError = Class.new(StandardError)

  included do
    worker_has_external_dependencies!

    sidekiq_options retry: 3

    sidekiq_retries_exhausted do |msg, error|
      cluster_id = msg['args'][0]

      cluster = Clusters::Cluster.find_by_id(cluster_id)

      cluster.make_cleanup_errored!("#{self.class.name} retried too many times") if cluster

      logger = Gitlab::Kubernetes::Logger.build

      logger.error({
        exception: error,
        cluster_id: cluster_id,
        class_name: msg['class'],
        event: :sidekiq_retries_exhausted,
        message: msg['error_message']
      })
    end
  end

  private

  # Override this method to customize the execution_limit
  def execution_limit
    DEFAULT_EXECUTION_LIMIT
  end

  def exceeded_execution_limit?(execution_count)
    execution_count >= execution_limit
  end

  def logger
    @logger ||= Gitlab::Kubernetes::Logger.build
  end

  def exceeded_execution_limit(cluster)
    log_exceeded_execution_limit_error(cluster)

    cluster.make_cleanup_errored!("#{self.class.name} exceeded the execution limit")
  end

  def log_exceeded_execution_limit_error(cluster)
    logger.error({
      exception: ExceededExecutionLimitError.name,
      cluster_id: cluster.id,
      class_name: self.class.name,
      cleanup_status: cluster.cleanup_status_name,
      event: :failed_to_remove_cluster_and_resources,
      message: "exceeded execution limit of #{execution_limit} tries"
    })
  end
end

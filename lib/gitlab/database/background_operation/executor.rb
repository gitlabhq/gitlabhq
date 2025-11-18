# frozen_string_literal: true

module Gitlab
  module Database
    module BackgroundOperation
      class Executor
        SubBatchTimeoutError = Class.new(StandardError)

        def initialize(connection:)
          @connection = connection
        end

        def perform(job)
          job.run!
          execute_job(job)
          job.succeed!
        rescue SubBatchTimeoutError => exception
          job.failure!(error: exception, from_sub_batch: true)
          raise SubBatchTimeoutError, exception
        rescue Exception => error # rubocop:disable Lint/RescueException -- need to save any kind of error
          job.failure!(error: error)
          raise
        end

        private

        attr_reader :connection

        def execute_job(job)
          worker_class = job.worker_job_class
          feature_category = fetch_feature_category(worker_class)

          ApplicationContext.push(feature_category: feature_category)

          worker_instance = create_worker_instance(worker_class, job)
          worker_instance.perform

          job.metrics = worker_instance.batch_metrics if worker_instance.respond_to?(:batch_metrics)
        end

        def create_worker_instance(worker_class, job)
          worker_attributes = job.worker_attributes.merge(
            connection: connection,
            sub_batch_exception: SubBatchTimeoutError
          )

          worker_class.new(**worker_attributes)
        end

        def fetch_feature_category(worker_class)
          return worker_class.feature_category.to_s if worker_class.respond_to?(:feature_category)

          Gitlab::BackgroundOperation::BaseOperationWorker::DEFAULT_FEATURE_CATEGORY
        end
      end
    end
  end
end

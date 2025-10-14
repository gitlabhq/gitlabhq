# frozen_string_literal: true

# rubocop:disable Gitlab/BoundedContexts -- Doesn't make sense to put this elsewhere
# rubocop:disable Scalability/CronWorkerContext -- No metadata needed as it's called from cronjobs
# rubocop:disable Sidekiq/EnforceDatabaseHealthSignalDeferral -- Not applicable here
module Database
  module BackgroundOperation
    class CronEnqueueWorker
      include ApplicationWorker

      include CronjobQueue

      data_consistency :sticky
      feature_category :database
      urgency :low
      idempotent!

      def perform(args = {})
        options = (args['options'] || {}).transform_keys(&:to_sym)

        Gitlab::Database::BackgroundOperation::WorkerCellLocal.enqueue(
          args['job_class_name'],
          args['table_name'],
          args['column_name'],
          job_arguments: args['job_arguments'],
          **options
        )
      end
    end
  end
end

# rubocop:enable Gitlab/BoundedContexts
# rubocop:enable Scalability/CronWorkerContext
# rubocop:enable Sidekiq/EnforceDatabaseHealthSignalDeferral

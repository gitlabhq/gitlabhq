# frozen_string_literal: true

module ContainerRegistry
  module Migration
    class ObserverWorker
      include ApplicationWorker
      # This worker does not perform work scoped to a context
      include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

      COUNT_BATCH_SIZE = 50000

      data_consistency :sticky
      feature_category :container_registry
      urgency :low
      deduplicate :until_executed, including_scheduled: true
      idempotent!

      def perform
        return unless ::ContainerRegistry::Migration.enabled?

        use_replica_if_available do
          ContainerRepository::MIGRATION_STATES.each do |state|
            relation = ContainerRepository.with_migration_state(state)
            count = ::Gitlab::Database::BatchCount.batch_count(
              relation, batch_size: COUNT_BATCH_SIZE
            )
            name = "#{state}_count".to_sym
            log_extra_metadata_on_done(name, count)
          end
        end
      end

      private

      def use_replica_if_available(&block)
        ::Gitlab::Database::LoadBalancing::Session.current.use_replicas_for_read_queries(&block)
      end
    end
  end
end

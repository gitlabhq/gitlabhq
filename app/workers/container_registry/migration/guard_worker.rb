# frozen_string_literal: true

module ContainerRegistry
  module Migration
    class GuardWorker
      include ApplicationWorker
      # This is a general worker with no context.
      # It is not scoped to a project, user or group.
      # We don't have a context.
      include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

      data_consistency :always
      feature_category :container_registry
      urgency :low
      worker_resource_boundary :unknown
      deduplicate :until_executed
      idempotent!

      def perform
        return unless Gitlab.com?

        repositories = ::ContainerRepository.with_stale_migration(step_before_timestamp)
                                            .limit(max_capacity)

        # the #to_a is safe as the amount of entries is limited.
        # In addition, we're calling #each in the next line and we don't want two different SQL queries for these two lines
        log_extra_metadata_on_done(:stale_migrations_count, repositories.to_a.size)

        repositories.each do |repository|
          repository.abort_import
        end
      end

      private

      def step_before_timestamp
        ::ContainerRegistry::Migration.max_step_duration.seconds.ago
      end

      def max_capacity
        # doubling the actual capacity to prevent issues in case the capacity
        # is not properly applied
        ::ContainerRegistry::Migration.capacity * 2
      end
    end
  end
end

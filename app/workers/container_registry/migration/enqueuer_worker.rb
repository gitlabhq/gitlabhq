# frozen_string_literal: true

module ContainerRegistry
  module Migration
    class EnqueuerWorker
      include ApplicationWorker
      include CronjobQueue # rubocop:disable Scalability/CronWorkerContext
      include Gitlab::Utils::StrongMemoize

      data_consistency :always
      feature_category :container_registry
      urgency :low
      deduplicate :until_executing, including_scheduled: true
      idempotent!

      def perform
        return unless migration.enabled?
        return unless below_capacity?
        return unless waiting_time_passed?

        re_enqueue_if_capacity if handle_aborted_migration || handle_next_migration
      rescue StandardError => e
        Gitlab::ErrorTracking.log_exception(
          e,
          next_repository_id: next_repository&.id,
          next_aborted_repository_id: next_aborted_repository&.id
        )

        next_repository&.abort_import
      end

      private

      def handle_aborted_migration
        return unless next_aborted_repository&.retry_aborted_migration

        log_extra_metadata_on_done(:container_repository_id, next_aborted_repository.id)
        log_extra_metadata_on_done(:import_type, 'retry')

        true
      end

      def handle_next_migration
        return unless next_repository
        # We return true because the repository was successfully processed (migration_state is changed)
        return true if tag_count_too_high?
        return unless next_repository.start_pre_import

        log_extra_metadata_on_done(:container_repository_id, next_repository.id)
        log_extra_metadata_on_done(:import_type, 'next')

        true
      end

      def tag_count_too_high?
        return false unless next_repository.tags_count > migration.max_tags_count

        next_repository.skip_import(reason: :too_many_tags)

        true
      end

      def below_capacity?
        current_capacity <= maximum_capacity
      end

      def waiting_time_passed?
        delay = migration.enqueue_waiting_time
        return true if delay == 0
        return true unless last_step_completed_repository

        last_step_completed_repository.last_import_step_done_at < Time.zone.now - delay
      end

      def current_capacity
        strong_memoize(:current_capacity) do
          ContainerRepository.with_migration_states(
            %w[pre_importing pre_import_done importing]
          ).count
        end
      end

      def maximum_capacity
        migration.capacity
      end

      def next_repository
        strong_memoize(:next_repository) do
          ContainerRepository.ready_for_import.take # rubocop:disable CodeReuse/ActiveRecord
        end
      end

      def next_aborted_repository
        strong_memoize(:next_aborted_repository) do
          ContainerRepository.with_migration_state('import_aborted').take # rubocop:disable CodeReuse/ActiveRecord
        end
      end

      def last_step_completed_repository
        strong_memoize(:last_step_completed_repository) do
          ContainerRepository.recently_done_migration_step.first
        end
      end

      def migration
        ::ContainerRegistry::Migration
      end

      def re_enqueue_if_capacity
        return unless current_capacity < maximum_capacity

        self.class.perform_async
      end
    end
  end
end

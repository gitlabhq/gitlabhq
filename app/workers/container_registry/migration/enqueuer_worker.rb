# frozen_string_literal: true

module ContainerRegistry
  module Migration
    class EnqueuerWorker
      include ApplicationWorker
      include CronjobQueue # rubocop:disable Scalability/CronWorkerContext
      include Gitlab::Utils::StrongMemoize
      include ExclusiveLeaseGuard

      DEFAULT_LEASE_TIMEOUT = 30.minutes.to_i.freeze

      data_consistency :always
      feature_category :container_registry
      urgency :low
      deduplicate :until_executing, including_scheduled: true
      idempotent!

      def perform
        re_enqueue = false
        try_obtain_lease do
          break unless runnable?

          re_enqueue = handle_aborted_migration || handle_next_migration
        end
        re_enqueue_if_capacity if re_enqueue
      end

      private

      def handle_aborted_migration
        return unless next_aborted_repository

        log_extra_metadata_on_done(:import_type, 'retry')
        log_repository(next_aborted_repository)

        next_aborted_repository.retry_aborted_migration

        true
      rescue StandardError => e
        Gitlab::ErrorTracking.log_exception(e, next_aborted_repository_id: next_aborted_repository&.id)

        true
      ensure
        log_repository_migration_state(next_aborted_repository)
      end

      def handle_next_migration
        return unless next_repository

        log_extra_metadata_on_done(:import_type, 'next')
        log_repository(next_repository)

        # We return true because the repository was successfully processed (migration_state is changed)
        return true if tag_count_too_high?
        return unless next_repository.start_pre_import

        true
      rescue StandardError => e
        Gitlab::ErrorTracking.log_exception(e, next_repository_id: next_repository&.id)
        next_repository&.abort_import

        false
      ensure
        log_repository_migration_state(next_repository)
      end

      def tag_count_too_high?
        return false unless next_repository.tags_count > migration.max_tags_count

        next_repository.skip_import(reason: :too_many_tags)
        log_extra_metadata_on_done(:tags_count_too_high, true)
        log_extra_metadata_on_done(:max_tags_count_setting, migration.max_tags_count)

        true
      end

      def below_capacity?
        current_capacity < maximum_capacity
      end

      def waiting_time_passed?
        delay = migration.enqueue_waiting_time
        return true if delay == 0
        return true unless last_step_completed_repository&.last_import_step_done_at

        last_step_completed_repository.last_import_step_done_at < Time.zone.now - delay
      end

      def runnable?
        unless migration.enabled?
          log_extra_metadata_on_done(:migration_enabled, false)
          return false
        end

        unless below_capacity?
          log_extra_metadata_on_done(:max_capacity_setting, maximum_capacity)
          log_extra_metadata_on_done(:below_capacity, false)

          return false
        end

        unless waiting_time_passed?
          log_extra_metadata_on_done(:waiting_time_passed, false)
          log_extra_metadata_on_done(:current_waiting_time_setting, migration.enqueue_waiting_time)

          return false
        end

        true
      end

      def current_capacity
        ContainerRepository.with_migration_states(
          %w[pre_importing pre_import_done importing]
        ).count
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
        return unless below_capacity?

        self.class.perform_async
      end

      def log_repository(repository)
        log_extra_metadata_on_done(:container_repository_id, repository&.id)
        log_extra_metadata_on_done(:container_repository_path, repository&.path)
      end

      def log_repository_migration_state(repository)
        return unless repository

        log_extra_metadata_on_done(:container_repository_migration_state, repository.migration_state)
      end

      # used by ExclusiveLeaseGuard
      def lease_key
        'container_registry:migration:enqueuer_worker'
      end

      # used by ExclusiveLeaseGuard
      def lease_timeout
        DEFAULT_LEASE_TIMEOUT
      end
    end
  end
end

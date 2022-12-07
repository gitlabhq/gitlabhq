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
      deduplicate :until_executing, ttl: DEFAULT_LEASE_TIMEOUT
      idempotent!

      def perform
        try_obtain_lease do
          while runnable? && Time.zone.now < loop_deadline
            repository_handled = handle_aborted_migration || handle_next_migration

            # no repository was found: stop the loop
            break unless repository_handled

            # we're going for another iteration so we need to clear memoization
            clear_memoization(:next_repository)
            clear_memoization(:next_aborted_repository)
            clear_memoization(:last_step_completed_repository)
          end
        end
      end

      def self.enqueue_a_job
        perform_async
      end

      private

      def handle_aborted_migration
        return unless next_aborted_repository

        next_aborted_repository.retry_aborted_migration

        true
      rescue StandardError => e
        Gitlab::ErrorTracking.log_exception(e, next_aborted_repository_id: next_aborted_repository&.id)

        false
      ensure
        log_repository_info(next_aborted_repository, import_type: 'retry')
      end

      def handle_next_migration
        return unless next_repository

        # We return true because the repository was successfully processed (migration_state is changed)
        return true if tag_count_too_high?
        return unless next_repository.start_pre_import

        true
      rescue StandardError => e
        Gitlab::ErrorTracking.log_exception(e, next_repository_id: next_repository&.id)
        next_repository&.abort_import

        false
      ensure
        log_repository_info(next_repository, import_type: 'next')
      end

      def tag_count_too_high?
        return false if migration.max_tags_count == 0
        return false unless next_repository.tags_count > migration.max_tags_count

        next_repository.skip_import(reason: :too_many_tags)

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
          # Using .limit(25)[0] instead of take here. Using a LIMIT 1 and 2 caused the query planner to
          # use an inefficient sequential scan instead of picking an index. LIMIT 25 works around
          # this issue.
          # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/87733 and
          # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/90735 for details.
          ContainerRepository.ready_for_import.ordered.limit(25)[0] # rubocop:disable CodeReuse/ActiveRecord
        end
      end

      def next_aborted_repository
        strong_memoize(:next_aborted_repository) do
          ContainerRepository.with_migration_state('import_aborted').ordered.limit(25)[0] # rubocop:disable CodeReuse/ActiveRecord
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

        self.class.enqueue_a_job
      end

      def log_info(extras)
        logger.info(structured_payload(extras))
      end

      def log_repository_info(repository, extras = {})
        return unless repository

        repository_info = {
          container_repository_id: repository.id,
          container_repository_path: repository.path,
          container_repository_migration_state: repository.migration_state
        }

        if repository.import_skipped?
          repository_info[:container_repository_migration_skipped_reason] = repository.migration_skipped_reason
        end

        log_info(extras.merge(repository_info))
      end

      def loop_deadline
        strong_memoize(:loop_deadline) do
          250.seconds.from_now
        end
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

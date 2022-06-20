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
      deduplicate :until_executed, ttl: 5.minutes
      idempotent!

      def perform
        return unless Gitlab.com?

        repositories = ::ContainerRepository.with_stale_migration(step_before_timestamp)
                                            .limit(max_capacity)
        aborts_count = 0
        long_running_migrations = []

        # the #to_a is safe as the amount of entries is limited.
        # In addition, we're calling #each in the next line and we don't want two different SQL queries for these two lines
        log_extra_metadata_on_done(:stale_migrations_count, repositories.to_a.size)

        repositories.each do |repository|
          if actively_importing?(repository)
            # if a repository is actively importing but not yet long_running, do nothing
            if long_running_migration?(repository)
              long_running_migrations << repository
              cancel_long_running_migration(repository)
              aborts_count += 1
            end
          else
            repository.abort_import
            aborts_count += 1
          end
        end

        log_extra_metadata_on_done(:aborted_stale_migrations_count, aborts_count)

        if long_running_migrations.any?
          log_extra_metadata_on_done(:aborted_long_running_migration_ids, long_running_migrations.map(&:id))
          log_extra_metadata_on_done(:aborted_long_running_migration_paths, long_running_migrations.map(&:path))
        end
      end

      private

      # A repository is actively_importing if it has an importing migration state
      # and that state matches the state in the registry
      # TODO We can have an API call n+1 situation here. It can be solved when the
      # endpoint accepts multiple repository paths at once. This is issue
      # https://gitlab.com/gitlab-org/container-registry/-/issues/582
      def actively_importing?(repository)
        return false unless repository.importing? || repository.pre_importing?
        return false unless external_state_matches_migration_state?(repository)

        true
      end

      def long_running_migration?(repository)
        timeout = if repository.migration_state == 'pre_importing'
                    migration.pre_import_timeout.seconds
                  else
                    migration.import_timeout.seconds
                  end

        if repository.migration_state == 'pre_importing' &&
           Feature.enabled?(:registry_migration_guard_dynamic_pre_import_timeout) &&
           migration_start_timestamp(repository).before?(timeout.ago)
          timeout = migration.dynamic_pre_import_timeout_for(repository)
        end

        migration_start_timestamp(repository).before?(timeout.ago)
      end

      def external_state_matches_migration_state?(repository)
        status = repository.external_import_status

        (status == 'pre_import_in_progress' && repository.pre_importing?) ||
          (status == 'import_in_progress' && repository.importing?)
      end

      def migration_start_timestamp(repository)
        if repository.pre_importing?
          repository.migration_pre_import_started_at
        else
          repository.migration_import_started_at
        end
      end

      def step_before_timestamp
        migration.max_step_duration.seconds.ago
      end

      def max_capacity
        # doubling the actual capacity to prevent issues in case the capacity
        # is not properly applied
        migration.capacity * 2
      end

      def migration
        ::ContainerRegistry::Migration
      end

      def cancel_long_running_migration(repository)
        result = repository.migration_cancel

        case result[:status]
        when :ok
          if repository.nearing_or_exceeded_retry_limit?
            repository.skip_import(reason: :migration_canceled)
          else
            repository.abort_import
          end
        when :bad_request
          repository.reconcile_import_status(result[:state]) do
            repository.abort_import
          end
        else
          repository.abort_import
        end
      end
    end
  end
end

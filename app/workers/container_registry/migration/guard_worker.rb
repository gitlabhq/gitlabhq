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
        aborts_count = 0
        long_running_migration_ids = []

        # the #to_a is safe as the amount of entries is limited.
        # In addition, we're calling #each in the next line and we don't want two different SQL queries for these two lines
        log_extra_metadata_on_done(:stale_migrations_count, repositories.to_a.size)

        repositories.each do |repository|
          if abortable?(repository)
            repository.abort_import
            aborts_count += 1
          else
            long_running_migration_ids << repository.id if long_running_migration?(repository)
          end
        end

        log_extra_metadata_on_done(:aborted_stale_migrations_count, aborts_count)

        if long_running_migration_ids.any?
          log_extra_metadata_on_done(:long_running_stale_migration_container_repository_ids, long_running_migration_ids)
        end
      end

      private

      # This can ping the Container Registry API.
      # We loop on a set of repositories to calls this function (see #perform)
      # In the worst case scenario, we have a n+1 API calls situation here.
      #
      # This is reasonable because the maximum amount of repositories looped
      # on is `25`. See ::ContainerRegistry::Migration.capacity.
      #
      # TODO We can remove this n+1 situation by having a Container Registry API
      # endpoint that accepts multiple repository paths at once. This is issue
      # https://gitlab.com/gitlab-org/container-registry/-/issues/582
      def abortable?(repository)
        # early return to save one Container Registry API request
        return true unless repository.importing? || repository.pre_importing?
        return true unless external_migration_in_progress?(repository)

        false
      end

      def long_running_migration?(repository)
        migration_start_timestamp(repository).before?(long_running_migration_threshold)
      end

      def external_migration_in_progress?(repository)
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
        ::ContainerRegistry::Migration.max_step_duration.seconds.ago
      end

      def max_capacity
        # doubling the actual capacity to prevent issues in case the capacity
        # is not properly applied
        ::ContainerRegistry::Migration.capacity * 2
      end

      def long_running_migration_threshold
        @threshold ||= 30.minutes.ago
      end
    end
  end
end

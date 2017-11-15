module Gitlab
  module Geo
    module LogCursor
      class Daemon
        VERSION = '0.2.0'.freeze
        BATCH_SIZE = 250

        attr_reader :options

        def initialize(options = {})
          @options = options
          @exit = false
          logger.geo_logger.build.level = options[:debug] ? :debug : Rails.logger.level
        end

        def run!
          trap_signals

          full_scan! if options[:full_scan]

          until exit?
            lease = Lease.try_obtain_with_ttl { run_once! }

            return if exit?

            # When no new event is found sleep for a few moments
            arbitrary_sleep(lease[:ttl])
          end
        end

        def run_once!
          LogCursor::Events.fetch_in_batches { |batch| handle_events(batch) }
        end

        # Execute routines to verify the required initial data is available
        # and mark non-replicated data as requiring replication.
        def full_scan!
          # This is slow and can be improved in the future by using PostgreSQL FDW
          # so we can query with a LEFT JOIN and have a list of
          # Projects without corresponding ProjectRegistry in the DR database
          # See: https://robots.thoughtbot.com/postgres-foreign-data-wrapper (requires PG 9.6)
          $stdout.print 'Searching for non replicated projects...'

          Gitlab::Geo.current_node.projects.select(:id).find_in_batches(batch_size: BATCH_SIZE) do |batch|
            $stdout.print '.'

            project_ids = batch.map(&:id)
            existing = ::Geo::ProjectRegistry.where(project_id: project_ids).pluck(:project_id)
            missing_projects = project_ids - existing

            logger.info(
              "Missing projects",
              projects: missing_projects,
              project_count: missing_projects.count)

            missing_projects.each do |id|
              ::Geo::ProjectRegistry.create(project_id: id)
            end
          end
          $stdout.puts 'Done!'
          puts
        end

        def handle_events(batch)
          batch.each do |event_log|
            next unless can_replay?(event_log)

            if event_log.repository_updated_event
              handle_repository_updated(event_log)
            elsif event_log.repository_created_event
              handle_repository_created(event_log)
            elsif event_log.repository_deleted_event
              handle_repository_deleted(event_log)
            elsif event_log.repositories_changed_event
              handle_repositories_changed(event_log.repositories_changed_event)
            elsif event_log.repository_renamed_event
              handle_repository_renamed(event_log)
            elsif event_log.hashed_storage_migrated_event
              handle_hashed_storage_migrated(event_log)
            end
          end
        end

        private

        def trap_signals
          trap(:TERM) do
            quit!
          end
          trap(:INT) do
            quit!
          end
        end

        # Safe shutdown
        def quit!
          $stdout.puts 'Exiting...'

          @exit = true
        end

        def exit?
          @exit
        end

        def can_replay?(event_log)
          return true if event_log.project_id.nil?

          Gitlab::Geo.current_node&.projects_include?(event_log.project_id)
        end

        def handle_repository_created(event_log)
          event = event_log.repository_created_event
          registry = find_or_initialize_registry(event.project_id, resync_repository: true, resync_wiki: event.wiki_path.present?)

          logger.event_info(
            event_log.created_at,
            message: 'Repository created',
            project_id: event.project_id,
            repo_path: event.repo_path,
            wiki_path: event.wiki_path,
            resync_repository: registry.resync_repository,
            resync_wiki: registry.resync_wiki)

          registry.save!

          ::Geo::ProjectSyncWorker.perform_async(event.project_id, Time.now)
        end

        def handle_repository_updated(event_log)
          event = event_log.repository_updated_event
          registry = find_or_initialize_registry(event.project_id, "resync_#{event.source}" => true)

          logger.event_info(
            event_log.created_at,
            message: 'Repository update',
            project_id: event.project_id,
            source: event.source,
            resync_repository: registry.resync_repository,
            resync_wiki: registry.resync_wiki)

          registry.save!

          ::Geo::ProjectSyncWorker.perform_async(event.project_id, Time.now)
        end

        def handle_repository_deleted(event_log)
          event = event_log.repository_deleted_event

          disk_path = File.join(event.repository_storage_path, event.deleted_path)

          job_id = ::Geo::RepositoryDestroyService
                     .new(event.project_id, event.deleted_project_name, disk_path, event.repository_storage_name)
                     .async_execute

          logger.event_info(
            event_log.created_at,
            message: 'Deleted project',
            project_id: event.project_id,
            disk_path: disk_path,
            job_id: job_id)

          # No need to create a project entry if it doesn't exist
          ::Geo::ProjectRegistry.where(project_id: event.project_id).delete_all
        end

        def handle_repositories_changed(event)
          return unless Gitlab::Geo.current_node.id == event.geo_node_id

          job_id = ::Geo::RepositoriesCleanUpWorker.perform_in(1.hour, event.geo_node_id)

          if job_id
            logger.info('Scheduled repositories clean up for Geo node', geo_node_id: event.geo_node_id, job_id: job_id)
          else
            logger.error('Could not schedule repositories clean up for Geo node', geo_node_id: event.geo_node_id)
          end
        end

        def handle_repository_renamed(event_log)
          event = event_log.repository_renamed_event
          return unless event.project_id

          old_path = event.old_path_with_namespace
          new_path = event.new_path_with_namespace

          job_id = ::Geo::RenameRepositoryService
                     .new(event.project_id, old_path, new_path)
                     .async_execute

          logger.event_info(
            event_log.created_at,
            message: 'Renaming project',
            project_id: event.project_id,
            old_path: old_path,
            new_path: new_path,
            job_id: job_id)
        end

        def handle_hashed_storage_migrated(event_log)
          event = event_log.hashed_storage_migrated_event
          return unless event.project_id

          job_id = ::Geo::HashedStorageMigrationService.new(
            event.project_id,
            old_disk_path: event.old_disk_path,
            new_disk_path: event.new_disk_path,
            old_storage_version: event.old_storage_version
          ).async_execute

          logger.event_info(
            event_log.created_at,
            message: 'Migrating project to hashed storage',
            project_id: event.project_id,
            old_storage_version: event.old_storage_version,
            new_storage_version: event.new_storage_version,
            old_disk_path: event.old_disk_path,
            new_disk_path: event.new_disk_path,
            job_id: job_id)
        end

        def find_or_initialize_registry(project_id, attrs)
          registry = ::Geo::ProjectRegistry.find_or_initialize_by(project_id: project_id)
          registry.assign_attributes(attrs)
          registry
        end

        # Sleeps for the expired TTL that remains on the lease plus some random seconds.
        #
        # This allows multiple GeoLogCursors to randomly process a batch of events,
        # without favouring the shortest path (or latency).
        def arbitrary_sleep(delay)
          sleep(delay + rand(1..20) * 0.1)
        end

        def logger
          Gitlab::Geo::LogCursor::Logger
        end
      end
    end
  end
end

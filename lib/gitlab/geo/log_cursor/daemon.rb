module Gitlab
  module Geo
    module LogCursor
      class Daemon
        VERSION = '0.1.0'.freeze
        POOL_WAIT = 5.seconds.freeze
        BATCH_SIZE = 250

        attr_reader :options

        def initialize(options = {})
          @options = options
          @exit = false
        end

        def run!
          trap_signals

          full_scan! if options[:full_scan]

          until exit?
            Events.fetch_in_batches do |batch|
              handle_events(batch)
            end

            return if exit?

            # When no new event is found sleep for a few moments
            sleep(POOL_WAIT)
          end
        end

        # Execute routines to verify the required initial data is available
        # and mark non-replicated data as requiring replication.
        def full_scan!
          # This is slow and can be improved in the future by using PostgreSQL FDW
          # so we can query with a LEFT JOIN and have a list of
          # Projects without corresponding ProjectRegistry in the DR database
          # See: https://robots.thoughtbot.com/postgres-foreign-data-wrapper (requires PG 9.6)
          $stdout.print 'Searching for non replicated projects...'
          Project.select(:id).find_in_batches(batch_size: BATCH_SIZE) do |batch|
            $stdout.print '.'

            project_ids = batch.map(&:id)
            existing = ::Geo::ProjectRegistry.where(project_id: project_ids).pluck(:project_id)
            missing_projects = project_ids - existing

            Gitlab::Geo::Logger.debug(
              class: self.class.name,
              message: "Missing projects",
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
          batch.each do |event|
            # Update repository
            if event.repository_updated_event
              handle_repository_update(event.repository_updated_event)
            elsif event.repository_deleted_event
              handle_repository_delete(event.repository_deleted_event)
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

        def handle_repository_update(updated_event)
          registry = ::Geo::ProjectRegistry.find_or_initialize_by(project_id: updated_event.project_id)

          case updated_event.source
          when 'repository'
            registry.resync_repository = true
          when 'wiki'
            registry.resync_wiki = true
          end

          Gitlab::Geo::Logger.info(
            class: self.class.name,
            message: "Repository update",
            cursor_delay_s: (Time.now - updated_event.created_at).to_f.round(3),
            project_id: updated_event.project_id,
            source: updated_event.source,
            resync_repository: registry.resync_repository,
            resync_wiki: registry.resync_wiki)

          registry.save!
        end

        def handle_repository_delete(deleted_event)
          # Once we remove system hooks we can refactor
          # GeoRepositoryDestroyWorker to avoid doing this
          full_path = File.join(deleted_event.repository_storage_path,
                                deleted_event.deleted_path)
          job_id = ::GeoRepositoryDestroyWorker.perform_async(
            deleted_event.project_id,
            deleted_event.deleted_project_name,
            full_path)
          Gitlab::Geo::Logger.info(
            class: self.class.name,
            message: "Deleted project",
            project_id: deleted_event.project_id,
            full_path: full_path,
            job_id: job_id)
          # No need to create a project entry if it doesn't exist
          ::Geo::ProjectRegistry.where(project_id: deleted_event.project_id).delete_all
        end

        def exit?
          @exit
        end
      end
    end
  end
end

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

          Gitlab::Geo.current_node.projects.select(:id).find_in_batches(batch_size: BATCH_SIZE) do |batch|
            $stdout.print '.'

            project_ids = batch.map(&:id)
            existing = ::Geo::ProjectRegistry.where(project_id: project_ids).pluck(:project_id)
            missing_projects = project_ids - existing

            Gitlab::Geo::Logger.info(
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
          batch.each do |event_log|
            next unless can_replay?(event_log)

            if event_log.repository_updated_event
              handle_repository_update(event_log)
            elsif event_log.repository_deleted_event
              handle_repository_delete(event_log)
            elsif event_log.repositories_changed_event
              handle_repositories_changed(event_log.repositories_changed_event)
            elsif event_log.repository_renamed_event
              handle_repository_rename(event_log)
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

        def handle_repository_update(event)
          updated_event = event.repository_updated_event
          registry = ::Geo::ProjectRegistry.find_or_initialize_by(project_id: updated_event.project_id)

          case updated_event.source
          when 'repository'
            registry.resync_repository = true
          when 'wiki'
            registry.resync_wiki = true
          end

          log_event_info(
            event.created_at,
            message: "Repository update",
            project_id: updated_event.project_id,
            source: updated_event.source,
            resync_repository: registry.resync_repository,
            resync_wiki: registry.resync_wiki)

          registry.save!
        end

        def handle_repository_delete(event)
          deleted_event = event.repository_deleted_event
          # Once we remove system hooks we can refactor
          # GeoRepositoryDestroyWorker to avoid doing this
          full_path = File.join(deleted_event.repository_storage_path,
                                deleted_event.deleted_path)
          job_id = ::Geo::RepositoryDestroyService
                     .new(deleted_event.project_id,
                          deleted_event.deleted_project_name,
                          full_path)
                     .async_execute
          log_event_info(event.created_at,
                         message: "Deleted project",
                         project_id: deleted_event.project_id,
                         full_path: full_path,
                         job_id: job_id)
          # No need to create a project entry if it doesn't exist
          ::Geo::ProjectRegistry.where(project_id: deleted_event.project_id).delete_all
        end

        def handle_repositories_changed(changed_event)
          return unless Gitlab::Geo.current_node.id == changed_event.geo_node_id

          job_id = ::Geo::RepositoriesCleanUpWorker.perform_in(1.hour, changed_event.geo_node_id)

          if job_id
            log_info('Scheduled repositories clean up for Geo node', geo_node_id: changed_event.geo_node_id, job_id: job_id)
          else
            log_error('Could not schedule repositories clean up for Geo node', geo_node_id: changed_event.geo_node_id)
          end
        end

        def handle_repository_rename(event)
          renamed_event = event.repository_renamed_event
          return unless renamed_event.project_id

          old_path = renamed_event.old_path_with_namespace
          new_path = renamed_event.new_path_with_namespace

          job_id = ::Geo::MoveRepositoryService
                     .new(renamed_event.project_id, "", old_path, new_path)
                     .async_execute

          log_event_info(event.created_at,
                         message: "Renaming project",
                         project_id: renamed_event.project_id,
                         old_path: old_path,
                         new_path: new_path,
                         job_id: job_id)
        end

        def cursor_delay(created_at)
          (Time.now - created_at).to_f.round(3)
        end

        def log_event_info(created_at, message, params = {})
          params[:cursor_delay_s] = cursor_delay(created_at)
          log_info(message, params)
        end

        def log_info(message, params = {})
          Gitlab::Geo::Logger.info({ class: self.class.name, message: message }.merge(params))
        end

        def log_error(message, params = {})
          Gitlab::Geo::Logger.error({ class: self.class.name, message: message }.merge(params))
        end
      end
    end
  end
end

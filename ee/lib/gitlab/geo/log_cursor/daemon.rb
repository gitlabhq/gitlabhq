module Gitlab
  module Geo
    module LogCursor
      class Daemon
        VERSION = '0.2.0'.freeze
        BATCH_SIZE = 250
        SECONDARY_CHECK_INTERVAL = 1.minute

        attr_reader :options

        def initialize(options = {})
          @options = options
          @exit = false
          logger.geo_logger.build.level = options[:debug] ? :debug : Rails.logger.level
        end

        def run!
          trap_signals

          until exit?
            # Prevent the node from processing events unless it's a secondary
            unless Geo.secondary?
              sleep(SECONDARY_CHECK_INTERVAL)
              next
            end

            lease = Lease.try_obtain_with_ttl { run_once! }

            return if exit?

            # When no new event is found sleep for a few moments
            arbitrary_sleep(lease[:ttl])
          end
        end

        def run_once!
          # Wrap this with the connection to make it possible to reconnect if
          # PGbouncer dies: https://github.com/rails/rails/issues/29189
          ActiveRecord::Base.connection_pool.with_connection do
            LogCursor::Events.fetch_in_batches { |batch| handle_events(batch) }
          end
        end

        def handle_events(batch)
          batch.each do |event_log|
            next unless can_replay?(event_log)

            begin
              event = event_log.event
              handler = "handle_#{event.class.name.demodulize.underscore}"

              __send__(handler, event, event_log.created_at) # rubocop:disable GitlabSecurity/PublicSend
            rescue NoMethodError => e
              logger.error(e.message)
              raise e
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

        def handle_repository_created_event(event, created_at)
          registry = find_or_initialize_registry(event.project_id, resync_repository: true, resync_wiki: event.wiki_path.present?)

          logger.event_info(
            created_at,
            'Repository created',
            project_id: event.project_id,
            repo_path: event.repo_path,
            wiki_path: event.wiki_path,
            resync_repository: registry.resync_repository,
            resync_wiki: registry.resync_wiki)

          registry.save!

          ::Geo::ProjectSyncWorker.perform_async(event.project_id, Time.now)
        end

        def handle_repository_updated_event(event, created_at)
          registry = find_or_initialize_registry(event.project_id,
            "resync_#{event.source}" => true, "#{event.source}_verification_checksum" => nil)

          registry.save!

          job_id = ::Geo::ProjectSyncWorker.perform_async(event.project_id, Time.now)

          logger.event_info(
            created_at,
            'Repository update',
            project_id: event.project_id,
            source: event.source,
            resync_repository: registry.resync_repository,
            resync_wiki: registry.resync_wiki,
            job_id: job_id)
        end

        def handle_repository_deleted_event(event, created_at)
          registry = find_or_initialize_registry(event.project_id)
          skippable = registry.new_record?

          params = {
            project_id: event.project_id,
            repository_storage_name: event.repository_storage_name,
            disk_path: event.deleted_path,
            skippable: skippable
          }

          unless skippable
            params[:job_id] = ::Geo::RepositoryDestroyService.new(
              event.project_id,
              event.deleted_project_name,
              event.deleted_path,
              event.repository_storage_name
            ).async_execute

            ::Geo::ProjectRegistry.where(project_id: event.project_id).delete_all
          end

          logger.event_info(created_at, 'Deleted project', params)
        end

        def handle_repositories_changed_event(event, created_at)
          return unless Gitlab::Geo.current_node.id == event.geo_node_id

          job_id = ::Geo::RepositoriesCleanUpWorker.perform_in(1.hour, event.geo_node_id)

          if job_id
            logger.info('Scheduled repositories clean up for Geo node', geo_node_id: event.geo_node_id, job_id: job_id)
          else
            logger.error('Could not schedule repositories clean up for Geo node', geo_node_id: event.geo_node_id)
          end
        end

        def handle_repository_renamed_event(event, created_at)
          return unless event.project_id

          registry = find_or_initialize_registry(event.project_id)
          skippable = registry.new_record?

          params = {
            project_id: event.project_id,
            old_path: event.old_path_with_namespace,
            new_path: event.new_path_with_namespace,
            skippable: skippable
          }

          unless skippable
            params[:job_id] = ::Geo::RenameRepositoryService.new(
              event.project_id,
              event.old_path_with_namespace,
              event.new_path_with_namespace
            ).async_execute
          end

          logger.event_info(created_at, 'Renaming project', params)
        end

        def handle_hashed_storage_migrated_event(event, created_at)
          return unless event.project_id

          registry = find_or_initialize_registry(event.project_id)
          skippable = registry.new_record?

          params = {
            project_id: event.project_id,
            old_storage_version: event.old_storage_version,
            new_storage_version: event.new_storage_version,
            old_disk_path: event.old_disk_path,
            new_disk_path: event.new_disk_path,
            skippable: skippable
          }

          unless skippable
            params[:job_id] = ::Geo::HashedStorageMigrationService.new(
              event.project_id,
              old_disk_path: event.old_disk_path,
              new_disk_path: event.new_disk_path,
              old_storage_version: event.old_storage_version
            ).async_execute
          end

          logger.event_info(created_at, 'Migrating project to hashed storage', params)
        end

        def handle_hashed_storage_attachments_event(event, created_at)
          job_id = ::Geo::HashedStorageAttachmentsMigrationService.new(
            event.project_id,
            old_attachments_path: event.old_attachments_path,
            new_attachments_path: event.new_attachments_path
          ).async_execute

          logger.event_info(
            created_at,
            'Migrating attachments to hashed storage',
            project_id: event.project_id,
            old_attachments_path: event.old_attachments_path,
            new_attachments_path: event.new_attachments_path,
            job_id: job_id
          )
        end

        def handle_lfs_object_deleted_event(event, created_at)
          file_path = File.join(LfsObjectUploader.root, event.file_path)

          job_id = ::Geo::FileRemovalWorker.perform_async(file_path)

          logger.event_info(
            created_at,
            'Deleted LFS object',
            oid: event.oid,
            file_id: event.lfs_object_id,
            file_path: file_path,
            job_id: job_id)

          ::Geo::FileRegistry.lfs_objects.where(file_id: event.lfs_object_id).delete_all
        end

        def handle_job_artifact_deleted_event(event, created_at)
          file_registry_job_artifacts = ::Geo::JobArtifactRegistry.where(artifact_id: event.job_artifact_id)
          return unless file_registry_job_artifacts.any? # avoid race condition

          file_path = File.join(::JobArtifactUploader.root, event.file_path)

          if File.file?(file_path)
            deleted = delete_file(file_path) # delete synchronously to ensure consistency
            return unless deleted # do not delete file from registry if deletion failed
          end

          logger.event_info(
            created_at,
            'Deleted job artifact',
            file_id: event.job_artifact_id,
            file_path: file_path)

          file_registry_job_artifacts.delete_all
        end

        def handle_upload_deleted_event(event, created_at)
          logger.event_info(
            created_at,
            'Deleted upload file',
            upload_id: event.upload_id,
            upload_type: event.upload_type,
            file_path: event.file_path,
            model_id: event.model_id,
            model_type: event.model_type)

          ::Geo::FileRegistry.where(file_id: event.upload_id, file_type: event.upload_type).delete_all
        end

        def find_or_initialize_registry(project_id, attrs = nil)
          registry = ::Geo::ProjectRegistry.find_or_initialize_by(project_id: project_id)
          registry.assign_attributes(attrs)
          registry
        end

        def delete_file(path)
          File.delete(path)
        rescue => ex
          logger.error("Failed to remove file", exception: ex.class.name, details: ex.message, filename: path)
          false
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

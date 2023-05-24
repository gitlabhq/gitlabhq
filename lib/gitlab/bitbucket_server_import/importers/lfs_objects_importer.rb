# frozen_string_literal: true

module Gitlab
  module BitbucketServerImport
    module Importers
      class LfsObjectsImporter
        include ParallelScheduling

        def execute
          log_info(import_stage: 'import_lfs_objects', message: 'starting')

          download_service = Projects::LfsPointers::LfsObjectDownloadListService.new(project)

          begin
            queue_workers(download_service) if project&.lfs_enabled?
          rescue StandardError => e
            track_import_failure!(project, exception: e)
          end

          log_info(import_stage: 'import_lfs_objects', message: 'finished')

          job_waiter
        end

        def sidekiq_worker_class
          ImportLfsObjectWorker
        end

        def collection_method
          :lfs_objects
        end

        def id_for_already_processed_cache(lfs_download_object)
          lfs_download_object.oid
        end

        private

        def queue_workers(download_service)
          download_service.each_list_item do |lfs_download_object|
            # Needs to come before `already_processed?` as `jobs_remaining` resets to zero when the job restarts and
            # jobs_remaining needs to be the total amount of enqueued jobs
            job_waiter.jobs_remaining += 1

            next if already_processed?(lfs_download_object)

            job_delay = calculate_job_delay(job_waiter.jobs_remaining)

            sidekiq_worker_class.perform_in(job_delay, project.id, lfs_download_object.as_json, job_waiter.key)

            mark_as_processed(lfs_download_object)
          end
        end
      end
    end
  end
end

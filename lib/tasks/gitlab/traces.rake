require 'logger'
require 'resolv-replace'

desc "GitLab | Archive legacy traces to trace artifacts"
namespace :gitlab do
  namespace :traces do
    task archive: :environment do
      logger = Logger.new(STDOUT)
      logger.info('Archiving legacy traces')

      Ci::Build.finished.without_archived_trace
        .order(id: :asc)
        .find_in_batches(batch_size: 1000) do |jobs|
        job_ids = jobs.map { |job| [job.id] }

        ArchiveTraceWorker.bulk_perform_async(job_ids)

        logger.info("Scheduled #{job_ids.count} jobs. From #{job_ids.min} to #{job_ids.max}")
      end
    end

    task migrate: :environment do
      logger = Logger.new(STDOUT)
      logger.info('Starting transfer of job traces')

      Ci::Build.joins(:project)
        .with_archived_trace_stored_locally
        .find_each(batch_size: 10) do |build|
        begin
          build.job_artifacts_trace.file.migrate!(ObjectStorage::Store::REMOTE)

          logger.info("Transferred job trace of #{build.id} to object storage")
        rescue => e
          logger.error("Failed to transfer artifacts of #{build.id} with error: #{e.message}")
        end
      end
    end
  end
end

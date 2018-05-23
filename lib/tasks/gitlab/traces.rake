require 'logger'
require 'resolv-replace'

desc "GitLab | Archive legacy traces to trace artifacts"
namespace :gitlab do
  namespace :traces do
    task archive: :environment do
      logger = Logger.new(STDOUT)
      logger.info('Archiving legacy traces')

      Ci::Build.finished
        .where('NOT EXISTS (?)',
          Ci::JobArtifact.select(1).trace.where('ci_builds.id = ci_job_artifacts.job_id'))
        .order(id: :asc)
        .find_in_batches(batch_size: 1000) do |jobs|
        job_ids = jobs.map { |job| [job.id] }

        ArchiveTraceWorker.bulk_perform_async(job_ids)

        logger.info("Scheduled #{job_ids.count} jobs. From #{job_ids.min} to #{job_ids.max}")
      end
    end

    task cleanup: :environment do
      logger = Logger.new(STDOUT)
      logger.info('Cleanup remaining traces')

      # Create a directory to move duplicated files in
      backup_path = File.join(Settings.shared.path, 'duplicated', 'traces')
      FileUtils.mkdir_p(backup_path)

      Dir.glob("#{Settings.gitlab_ci.builds_path}/**/**/*.log") do |entry|
        file_name = File.basename(entry)
        job_id = file_name.scan(/(\d+)\.log/).first.first.to_i

        build = Ci::Build.find_by_id(job_id)

        if build.nil?
          logger.warn("id: #{job_id.to_s.rjust(8)} msg: build is not found")

          FileUtils.mv(entry, File.join(backup_path, file_name))
        elsif build.job_artifacts_trace&.file&.file&.exists?
          if build.job_artifacts_trace.file_store == ObjectStorage::Store::REMOTE
            logger.warn("id: #{job_id.to_s.rjust(8)} msg: build has already had an archived trace in object storage")

            FileUtils.mv(entry, File.join(backup_path, file_name))
          elsif build.job_artifacts_trace.file_store == ObjectStorage::Store::LOCAL || !build.job_artifacts_trace.file_store
            logger.warn("id: #{job_id.to_s.rjust(8)} msg: build has already had an archived trace in file storage")

            FileUtils.mv(entry, File.join(backup_path, file_name))
            build.job_artifacts_trace.file.schedule_background_upload # Schedule to upload the local file to the object storage
          end
        else
          logger.warn("id: #{job_id.to_s.rjust(8)} file_size: #{File.size(entry).to_s.rjust(8)} msg: build has not had an archived trace yet")

          ArchiveTraceWorker.perform_async(job_id) # Schedule to archive the trace
        end
      end
    end
  end
end

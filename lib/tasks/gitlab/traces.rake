require 'logger'
require 'resolv-replace'

desc "GitLab | Archive legacy traces to trace artifacts"
namespace :gitlab do
  namespace :traces do
    task archive: :environment do
      logger = Logger.new(STDOUT)
      logger.info('Archiving legacy traces')

      job_ids = Ci::Build.complete.without_trace_artifact.pluck(:id)
      job_ids = job_ids.map { |build_id| [build_id] }

      ArchiveLegacyTraceWorker.bulk_perform_async(job_ids)
    end
  end
end

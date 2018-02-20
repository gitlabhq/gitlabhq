require 'logger'
require 'resolv-replace'

desc "GitLab | Migrate files for artifacts to comply with new storage format"
namespace :gitlab do
  namespace :data_loss do
    task simulate: :environment do
      logger = Logger.new(STDOUT)
      logger.info('Simulating...')

      SAMPLE = 100

      project = Project.find_by(id: 28)
      user = User.first
      pipeline = Ci::Pipeline.last
      last_job_id = Ci::Build.last.id

      logger.info("last_job_id: #{last_job_id}")

      loop do
        if Ci::Build.where('id > ?', last_job_id).count < SAMPLE
          job = FactoryBot.create(:ci_build, :success, :trace_live, project: project, user: user, pipeline: pipeline)
          CreateTraceArtifactWorker.perform_async(job.id)
        end

        trace_artifacts = Ci::JobArtifact.where(file_store: 2).where('job_id > ?', last_job_id)
        trace_artifacts.each { |t| t.file.migrate!(ObjectStorage::Store::LOCAL) }

        break if Ci::JobArtifact.where(file_store: 1).where('job_id > ?', last_job_id).count == SAMPLE
      end

      success = Ci::JobArtifact.where('job_id > ?', last_job_id).all.inject(0) do |sum, trace_artifact|
        raise 'Unexpected' unless trace_artifact.file_store == ObjectStorage::Store::LOCAL
        sum += 1 if trace_artifact.file.file.exists?
        sum
      end

      # Ci::JobArtifact.where('job_id > ?', last_job_id).each do |trace_artifact|
      #   logger.info("trace_artifact: #{trace_artifact.inspect}")
      # end

      loss = ((SAMPLE - success).to_f / SAMPLE.to_f) * 100.0

      logger.info("Sample: #{SAMPLE}. Loss rate: #{loss}")
    end
  end
end

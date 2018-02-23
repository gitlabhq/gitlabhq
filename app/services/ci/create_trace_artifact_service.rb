module Ci
  class CreateTraceArtifactService < BaseService
    def execute(job)
      return if job.job_artifacts_trace

      job.trace.read do |stream|
        return unless stream.file?

        temp_file!(JobArtifactUploader.workhorse_upload_path) do |temp_path|
          FileUtils.cp(stream.path, temp_path)
          create_job_trace!(temp_path)
          FileUtils.rm(stream.path)
        end
      end
    end

    private

    def create_job_trace!(path)
      job.create_job_artifacts_trace!(
        project: job.project,
        file_type: :trace,
        file: UploadedFile.new(path, 'build.log', 'application/octet-stream')
      )
    end

    def temp_file!(temp_dir)
      FileUtils.mkdir_p(temp_dir)
      temp_file = Tempfile.new('file', temp_dir)
      temp_file&.close
      yield(temp_file.path)
    ensure
      temp_file&.close
      temp_file&.unlink
    end
  end
end

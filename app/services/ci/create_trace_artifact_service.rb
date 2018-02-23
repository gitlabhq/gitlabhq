module Ci
  class CreateTraceArtifactService < BaseService
    def execute(job)
      return if job.job_artifacts_trace

      job.trace.read do |stream|
        return unless stream.file?

        temp_file!(stream.path, JobArtifactUploader.workhorse_upload_path) do |temp_path|
          job.create_job_artifacts_trace!(
            project: job.project,
            file_type: :trace,
            file: UploadedFile.new(temp_path, 'job.log', 'application/octet-stream')
          )
        end

        raise 'Trace artifact not found' unless job.job_artifacts_trace.file.exists?

        FileUtils.rm(stream.path)
      end
    end

    private

    def temp_file!(src_file, temp_dir)
      FileUtils.mkdir_p(temp_dir)
      temp_file = Tempfile.new('trace-tmp-', temp_dir)
      temp_file&.close
      FileUtils.cp(src_file, temp_file.path)
      yield(temp_file.path)
    ensure
      temp_file&.close
      temp_file&.unlink
    end
  end
end

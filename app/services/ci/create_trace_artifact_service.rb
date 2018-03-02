module Ci
  class CreateTraceArtifactService < BaseService
    def execute(job)
      return if job.job_artifacts_trace

      job.trace.read do |stream|
        break unless stream.file?

        clone_file!(stream.path, JobArtifactUploader.workhorse_upload_path) do |clone_path|
          create_job_trace!(job, clone_path)
          FileUtils.rm(stream.path)
        end
      end
    end

    private

    def create_job_trace!(job, path)
      File.open(path) do |stream|
        job.create_job_artifacts_trace!(
          project: job.project,
          file_type: :trace,
          file: stream)
      end
    end

    def clone_file!(src_path, temp_dir)
      FileUtils.mkdir_p(temp_dir)
      Dir.mktmpdir('tmp-trace', temp_dir) do |dir_path|
        temp_path = File.join(dir_path, "job.log")
        FileUtils.copy(src_path, temp_path)
        yield(temp_path)
      end
    end
  end
end

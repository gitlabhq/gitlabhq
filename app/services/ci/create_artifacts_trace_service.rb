module Ci
  class CreateArtifactsTraceService < BaseService
    def execute(job_id)
      Ci::Build.find_by(id: job_id).try do |job|
        return if job.job_artifacts_trace

        job.trace.read do |stream|
          job.create_job_artifacts_trace!(
            project: job.project,
            file_type: :trace,
            file: stream.path) if stream.file?
        end
      end
    end
  end
end

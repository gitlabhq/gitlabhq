module Ci
  class CreateTraceArtifactService < BaseService
    def execute(job)
      return if job.job_artifacts_trace

      job.trace.read do |stream|
        if stream.file?
          job.create_job_artifacts_trace!(
            project: job.project,
            file_type: :trace,
            file: stream)
        end
      end
    end
  end
end

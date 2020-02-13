# frozen_string_literal: true

module API
  module Entities
    class Job < Entities::JobBasic
      # artifacts_file is included in job_artifacts, but kept for backward compatibility (remove in api/v5)
      expose :artifacts_file, using: Entities::JobArtifactFile, if: -> (job, opts) { job.artifacts? }
      expose :job_artifacts, as: :artifacts, using: Entities::JobArtifact
      expose :runner, with: Entities::Runner
      expose :artifacts_expire_at
    end
  end
end

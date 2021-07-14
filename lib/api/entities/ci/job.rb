# frozen_string_literal: true

module API
  module Entities
    module Ci
      class Job < JobBasic
        # artifacts_file is included in job_artifacts, but kept for backward compatibility (remove in api/v5)
        expose :artifacts_file, using: ::API::Entities::Ci::JobArtifactFile, if: -> (job, opts) { job.artifacts? }
        expose :job_artifacts, as: :artifacts, using: ::API::Entities::Ci::JobArtifact
        expose :runner, with: ::API::Entities::Ci::Runner
        expose :artifacts_expire_at
        expose :tag_list do |job|
          job.tags.map(&:name).sort
        end
      end
    end
  end
end

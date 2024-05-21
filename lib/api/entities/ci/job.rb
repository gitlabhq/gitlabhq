# frozen_string_literal: true

module API
  module Entities
    module Ci
      class Job < JobBasic
        # artifacts_file is included in job_artifacts, but kept for backward compatibility (remove in api/v5)
        expose :artifacts_file, using: ::API::Entities::Ci::JobArtifactFile, if: ->(job, opts) { job.artifacts? }
        expose :job_artifacts, as: :artifacts,
          using: ::API::Entities::Ci::JobArtifact,
          documentation: { is_array: true }
        expose :runner, with: ::API::Entities::Ci::Runner
        expose :runner_manager, with: ::API::Entities::Ci::RunnerManager, if: ->(job) { job.is_a?(::Ci::Build) }
        expose :artifacts_expire_at,
          documentation: { type: 'dateTime', example: '2016-01-19T09:05:50.355Z' }
        expose :archived?, as: :archived, documentation: { type: 'boolean', example: false }

        expose(
          :tag_list,
          documentation: { type: 'string', is_array: true, example: ['ubuntu18', 'docker runner'] }
        ) do |job|
          job.tags.map(&:name).sort
        end
      end
    end
  end
end

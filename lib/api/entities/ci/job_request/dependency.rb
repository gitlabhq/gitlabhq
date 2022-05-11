# frozen_string_literal: true

module API
  module Entities
    module Ci
      module JobRequest
        class Dependency < Grape::Entity
          expose :id, :name

          expose :token do |job, options|
            if ::Feature.enabled?(:ci_expose_running_job_token_for_artifacts, job.project)
              options[:running_job]&.token
            else
              job.token
            end
          end

          expose :artifacts_file, using: Entities::Ci::JobArtifactFile, if: ->(job, _) { job.available_artifacts? }
        end
      end
    end
  end
end

# frozen_string_literal: true

module API
  module Entities
    module JobRequest
      class Dependency < Grape::Entity
        expose :id, :name, :token
        expose :artifacts_file, using: Entities::JobArtifactFile, if: ->(job, _) { job.artifacts? }
      end
    end
  end
end

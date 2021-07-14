# frozen_string_literal: true

module API
  module Entities
    module Ci
      module JobRequest
        class Dependency < Grape::Entity
          expose :id, :name, :token
          expose :artifacts_file, using: Entities::Ci::JobArtifactFile, if: ->(job, _) { job.artifacts? }
        end
      end
    end
  end
end

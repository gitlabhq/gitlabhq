# frozen_string_literal: true

module API
  module Entities
    module Ci
      module JobRequest
        class Dependency < Grape::Entity
          expose :id, :name

          expose :token do |job, options|
            options[:running_job]&.token
          end

          expose :artifacts_file, using: Entities::Ci::JobArtifactFile, if: ->(job, _) { job.available_artifacts? }
        end
      end
    end
  end
end

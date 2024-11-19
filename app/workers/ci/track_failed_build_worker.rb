# frozen_string_literal: true

# Worker for tracking exit codes of failed CI jobs
module Ci
  class TrackFailedBuildWorker
    include ApplicationWorker
    include PipelineBackgroundQueue

    feature_category :static_application_security_testing

    urgency :low
    data_consistency :sticky
    worker_resource_boundary :cpu
    idempotent!
    worker_has_external_dependencies!

    def perform(build_id, exit_code, failure_reason)
      ::Ci::Build.find_by_id(build_id).try do |build|
        ::Ci::TrackFailedBuildService.new(
          build: build,
          exit_code: exit_code,
          failure_reason: failure_reason).execute
      end
    end
  end
end

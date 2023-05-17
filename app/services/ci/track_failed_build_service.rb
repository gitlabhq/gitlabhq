# frozen_string_literal: true

# This service tracks failed CI builds using Snowplow.
#
# @param build [Ci::Build] the build that failed.
# @param exit_code [Int] the resulting exit code.
module Ci
  class TrackFailedBuildService
    SCHEMA_URL = 'iglu:com.gitlab/ci_build_failed/jsonschema/1-0-2'

    def initialize(build:, exit_code:, failure_reason:)
      @build = build
      @exit_code = exit_code
      @failure_reason = failure_reason
    end

    def execute
      # rubocop:disable Style/IfUnlessModifier
      unless @build.failed?
        return ServiceResponse.error(message: 'Attempted to track a non-failed CI build')
      end

      # rubocop:enable Style/IfUnlessModifier

      context = SnowplowTracker::SelfDescribingJson.new(SCHEMA_URL, payload)

      ::Gitlab::Tracking.event(
        'ci::build',
        'failed',
        context: [context],
        user: @build.user,
        project: @build.project_id)

      ServiceResponse.success
    end

    private

    def payload
      {
        build_id: @build.id,
        build_name: @build.name,
        build_artifact_types: @build.job_artifact_types,
        exit_code: @exit_code,
        failure_reason: @failure_reason,
        project: @build.project_id
      }
    end
  end
end

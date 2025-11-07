# frozen_string_literal: true

module Ci
  class BuildFinishedWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :sticky

    sidekiq_options retry: 3

    queue_namespace :pipeline_processing
    feature_category :continuous_integration
    urgency :high
    worker_resource_boundary :cpu

    ARCHIVE_TRACES_IN = 2.minutes.freeze

    def perform(build_id)
      return unless build = Ci::Build.find_by_id(build_id)
      return unless build.project
      return if build.project.pending_delete?
      return unless pipeline = build.pipeline

      process_build(build, pipeline)
    end

    private

    # Processes a single CI build that has finished.
    #
    # This logic resides in a separate method so that EE can extend it more
    # easily.
    #
    # @param [Ci::Build] build The build to process.
    def process_build(build, pipeline)
      # We execute these in sync to reduce IO.
      build.update_coverage
      Ci::BuildReportResultService.new.execute(build)

      build.execute_hooks
      ChatNotificationWorker.perform_async(build.id) if pipeline.chat?
      build.track_deployment_usage
      build.track_verify_environment_usage
      build.remove_token!

      if build.failed? && !build.auto_retry_expected?
        ::Ci::MergeRequests::AddTodoWhenBuildFailsWorker.perform_async(build.id)
      end

      ##
      # We want to delay sending a build trace to object storage operation to
      # validate that this fixes a race condition between this and flushing live
      # trace chunks and chunks being removed after consolidation and putting
      # them into object storage archive.
      #
      # TODO This is temporary fix we should improve later, after we validate
      # that this is indeed the culprit.
      #
      # See https://gitlab.com/gitlab-org/gitlab/-/issues/267112 for more
      # details.
      #
      Ci::ArchiveTraceWorker.perform_in(ARCHIVE_TRACES_IN, build.id)

      Ci::Slsa::PublishProvenanceWorker.perform_async(build.id) if should_publish_provenance?(build)
    end

    def should_publish_provenance?(build)
      return false unless Feature.enabled?(:slsa_provenance_statement, build.project)
      return false unless build.artifacts?
      return false unless build.yaml_variables.any? { |variable| variable[:key] == "GENERATE_PROVENANCE" }
      return false unless build.project.public?

      true
    end
  end
end

Ci::BuildFinishedWorker.prepend_mod_with('Ci::BuildFinishedWorker')

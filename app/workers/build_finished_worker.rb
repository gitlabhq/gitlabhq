# frozen_string_literal: true

class BuildFinishedWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker
  include PipelineQueue

  queue_namespace :pipeline_processing
  urgency :high
  worker_resource_boundary :cpu
  tags :requires_disk_io

  ARCHIVE_TRACES_IN = 2.minutes.freeze

  # rubocop: disable CodeReuse/ActiveRecord
  def perform(build_id)
    Ci::Build.find_by(id: build_id).try do |build|
      process_build(build)
    end
  end
  # rubocop: enable CodeReuse/ActiveRecord

  private

  # Processes a single CI build that has finished.
  #
  # This logic resides in a separate method so that EE can extend it more
  # easily.
  #
  # @param [Ci::Build] build The build to process.
  def process_build(build)
    # We execute these in sync to reduce IO.
    BuildTraceSectionsWorker.new.perform(build.id)
    BuildCoverageWorker.new.perform(build.id)
    Ci::BuildReportResultWorker.new.perform(build.id)

    # TODO: As per https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/194, it may be
    # best to avoid creating more workers that we have no intention of calling async.
    # Change the previous worker calls on top to also just call the service directly.
    Ci::TestCasesService.new.execute(build)

    # We execute these async as these are independent operations.
    BuildHooksWorker.perform_async(build.id)
    ExpirePipelineCacheWorker.perform_async(build.pipeline_id) if build.pipeline.cacheable?
    ChatNotificationWorker.perform_async(build.id) if build.pipeline.chat?

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
    ArchiveTraceWorker.perform_in(ARCHIVE_TRACES_IN, build.id)
  end
end

BuildFinishedWorker.prepend_if_ee('EE::BuildFinishedWorker')

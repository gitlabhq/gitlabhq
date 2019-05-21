# frozen_string_literal: true

class BuildFinishedWorker
  include ApplicationWorker
  include PipelineQueue

  queue_namespace :pipeline_processing

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

    # We execute these async as these are independent operations.
    BuildHooksWorker.perform_async(build.id)
    ArchiveTraceWorker.perform_async(build.id)
    ExpirePipelineCacheWorker.perform_async(build.pipeline_id)
    ChatNotificationWorker.perform_async(build.id) if build.pipeline.chat?
  end
end

class BuildFinishedWorker
  include ApplicationWorker
  include PipelineQueue

  queue_namespace :pipeline_processing

  def perform(build_id)
    Ci::Build.find_by(id: build_id).try do |build|
      # Swap all trace chunks to Database from Redis
      # TODO: Do we need that?
      build.chunks.redis.map(&:use_database!)

      # We execute that in sync as this access the files in order to access local data, and reduce IO
      BuildTraceSectionsWorker.new.perform(build.id)
      BuildCoverageWorker.new.perform(build.id)

      # We execute that async as this are two indepentent operations that can be executed after TraceSections and Coverage
      BuildHooksWorker.perform_async(build.id)
      ArchiveTraceWorker.perform_async(build.id)
    end
  end
end

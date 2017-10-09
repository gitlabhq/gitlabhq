class BuildFinishedWorker
  include Sidekiq::Worker
  include PipelineQueue

  enqueue_in group: :processing

  def perform(build_id)
    Ci::Build.find_by(id: build_id).try do |build|
<<<<<<< HEAD
      UpdateBuildMinutesService.new(build.project, nil).execute(build)
=======
      BuildTraceSectionsWorker.perform_async(build.id)
>>>>>>> ce-com/master
      BuildCoverageWorker.new.perform(build.id)
      BuildHooksWorker.new.perform(build.id)
    end
  end
end

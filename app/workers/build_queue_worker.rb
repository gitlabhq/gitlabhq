class BuildQueueWorker
  include Sidekiq::Worker
  include BuildQueue

  def perform(build_id)
    Ci::Build.find_by(id: build_id).try do |build|
      Ci::UpdateBuildQueueService.new.execute(build)
    end
  end
end

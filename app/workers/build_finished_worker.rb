class BuildFinishedWorker
  include Sidekiq::Worker

  def perform(build_id)
    Ci::Build.find_by(id: build_id).try do |build|
      BuildCoverageWorker.new.perform(build.id)
      BuildHooksWorker.new.perform(build.id)
    end
  end
end

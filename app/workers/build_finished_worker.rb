class BuildFinishedWorker
  include Sidekiq::Worker

  def perform(build_id)
    Ci::Build.find_by(id: build_id).try do |build|
      build.with_lock do
        BuildCoverageWorker.new.perform(build.id)
        BuildHooksWorker.new.perform(build.id)
      end
    end
  end
end

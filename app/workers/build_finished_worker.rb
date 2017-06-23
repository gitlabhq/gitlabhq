class BuildFinishedWorker
  include Sidekiq::Worker
  include BuildQueue

  def perform(build_id)
    Ci::Build.find_by(id: build_id)&.tap do |build|
      BuildCoverageWorker.new.perform(build.id)
      BuildHooksWorker.new.perform(build.id)

      build.clear_token!
    end
  end
end

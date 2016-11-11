class BuildCoverageWorker
  include Sidekiq::Worker
  include BuildQueue

  def perform(build_id)
    Ci::Build.find_by(id: build_id)
      .try(:update_coverage)
  end
end

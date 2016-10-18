class BuildCoverageWorker
  include Sidekiq::Worker
  sidekiq_options queue: :default

  def perform(build_id)
    Ci::Build.find_by(id: build_id)
      .try(:update_coverage)
  end
end

# frozen_string_literal: true

class ExpireBuildArtifactsWorker
  include ApplicationWorker
  include CronjobQueue

  feature_category :continuous_integration

  def perform
    Ci::DestroyExpiredJobArtifactsService.new.execute
  end
end

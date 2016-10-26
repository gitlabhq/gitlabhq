class RequestsProfilesWorker
  include Sidekiq::Worker
  include CronjobQueue

  def perform
    Gitlab::RequestProfiler.remove_all_profiles
  end
end

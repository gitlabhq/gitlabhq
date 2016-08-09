class RequestsProfilesWorker
  include Sidekiq::Worker

  sidekiq_options queue: :default

  def perform
    Gitlab::RequestProfiler.remove_all_profiles
  end
end

# frozen_string_literal: true

class RequestsProfilesWorker
  include ApplicationWorker
  include CronjobQueue

  def perform
    Gitlab::RequestProfiler.remove_all_profiles
  end
end

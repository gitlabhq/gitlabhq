# frozen_string_literal: true

class RequestsProfilesWorker
  include ApplicationWorker
  include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

  feature_category :source_code_management

  def perform
    Gitlab::RequestProfiler.remove_all_profiles
  end
end

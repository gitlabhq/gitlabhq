# frozen_string_literal: true

# DEPRECATED
#
# To be removed by https://gitlab.com/gitlab-org/gitlab/-/issues/366573
class ClusterWaitForAppUpdateWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  include ClusterQueue
  include ClusterApplications

  INTERVAL = 10.seconds
  TIMEOUT = 20.minutes

  loggable_arguments 0

  def perform(app_name, app_id); end
end

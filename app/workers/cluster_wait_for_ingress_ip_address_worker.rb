# frozen_string_literal: true

# DEPRECATED
#
# To be removed by https://gitlab.com/gitlab-org/gitlab/-/issues/366573
class ClusterWaitForIngressIpAddressWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  include ClusterQueue
  include ClusterApplications

  worker_has_external_dependencies!
  loggable_arguments 0

  def perform(app_name, app_id); end
end

# frozen_string_literal: true

# DEPRECATED
#
# To be removed by https://gitlab.com/gitlab-org/gitlab/-/issues/366573
class ClusterConfigureIstioWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  include ClusterQueue

  worker_has_external_dependencies!

  def perform(cluster_id); end
end

# frozen_string_literal: true

class ClusterConfigureWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker
  include ClusterQueue

  def perform(cluster_id)
    # Scheduled for removal in https://gitlab.com/gitlab-org/gitlab-foss/issues/59319
  end
end

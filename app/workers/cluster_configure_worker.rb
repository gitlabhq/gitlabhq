# frozen_string_literal: true

class ClusterConfigureWorker
  include ApplicationWorker
  include ClusterQueue

  def perform(cluster_id)
    # Scheduled for removal in https://gitlab.com/gitlab-org/gitlab-ce/issues/59319
  end
end

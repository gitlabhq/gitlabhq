# frozen_string_literal: true

class ClusterProjectConfigureWorker
  include ApplicationWorker
  include ClusterQueue

  def perform(project_id)
    # Scheduled for removal in https://gitlab.com/gitlab-org/gitlab-ce/issues/59319
  end
end

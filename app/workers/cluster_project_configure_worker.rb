# frozen_string_literal: true

class ClusterProjectConfigureWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker
  include ClusterQueue

  worker_has_external_dependencies!

  def perform(project_id)
    # Scheduled for removal in https://gitlab.com/gitlab-org/gitlab-foss/issues/59319
  end
end

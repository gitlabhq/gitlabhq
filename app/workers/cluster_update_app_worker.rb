# frozen_string_literal: true

# Deprecated, to be removed in %14.0 as part of https://gitlab.com/groups/gitlab-org/-/epics/4280
# Also see  https://gitlab.com/gitlab-org/gitlab/-/issues/366573
class ClusterUpdateAppWorker # rubocop:disable Scalability/IdempotentWorker
  UpdateAlreadyInProgressError = Class.new(StandardError)

  include ApplicationWorker

  data_consistency :always
  include ClusterQueue
  include ClusterApplications
  include ExclusiveLeaseGuard

  sidekiq_options retry: 3, dead: false
  loggable_arguments 0, 3

  LEASE_TIMEOUT = 10.minutes.to_i

  def perform(app_name, app_id, project_id, scheduled_time); end
end

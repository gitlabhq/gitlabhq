# frozen_string_literal: true

class RepositoryUpdateRemoteMirrorWorker
  UpdateError = Class.new(StandardError)

  include ApplicationWorker

  data_consistency :always
  include Gitlab::ExclusiveLeaseHelpers

  worker_has_external_dependencies!

  sidekiq_options retry: 3, dead: false
  feature_category :source_code_management
  loggable_arguments 1
  idempotent!

  LOCK_WAIT_TIME = 30.seconds
  MAX_TRIES = 3

  def perform(remote_mirror_id, scheduled_time, tries = 0)
    remote_mirror = RemoteMirror.find_by_id(remote_mirror_id)
    return unless remote_mirror
    return if remote_mirror.updated_since?(scheduled_time)

    # If the update is already running, wait for it to finish before running again
    # This will wait for a total of 90 seconds in 3 steps
    in_lock(
      remote_mirror_update_lock(remote_mirror.id),
      retries: 3,
      ttl: remote_mirror.max_runtime,
      sleep_sec: LOCK_WAIT_TIME
    ) do
      update_mirror(remote_mirror, scheduled_time, tries)
    end
  rescue Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError
    # If an update runs longer than 1.5 minutes, we'll reschedule it
    # with a backoff. The next run will check if the previous update would
    # include the changes that triggered this update and become a no-op.
    self.class.perform_in(remote_mirror.backoff_delay, remote_mirror.id, scheduled_time, tries)
  end

  private

  def update_mirror(mirror, scheduled_time, tries)
    project = mirror.project
    current_user = project.creator
    result = Projects::UpdateRemoteMirrorService.new(project, current_user).execute(mirror, tries)

    if result[:status] == :error && mirror.to_retry?
      schedule_retry(mirror, scheduled_time, tries)
    end
  end

  def remote_mirror_update_lock(mirror_id)
    [self.class.name, mirror_id].join(':')
  end

  def schedule_retry(mirror, scheduled_time, tries)
    retry_time = if Feature.enabled?(:remote_mirror_retry_with_delay, mirror.project)
                   Time.current + 1.second
                 else
                   scheduled_time
                 end

    self.class.perform_in(mirror.backoff_delay, mirror.id, retry_time, tries + 1)
  end
end

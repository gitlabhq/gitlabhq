# frozen_string_literal: true

class DeleteContainerRepositoryWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker
  include ExclusiveLeaseGuard

  data_consistency :always

  sidekiq_options retry: 3

  queue_namespace :container_repository
  feature_category :container_registry

  LEASE_TIMEOUT = 1.hour.freeze
  FIXED_DELAY = 10.seconds.freeze

  attr_reader :container_repository

  def perform(current_user_id, container_repository_id)
    current_user = User.find_by_id(current_user_id)
    @container_repository = ContainerRepository.find_by_id(container_repository_id)
    project = container_repository&.project

    return unless current_user && container_repository && project

    if migration.delete_container_repository_worker_support? && migrating?
      delay = migration_duration

      self.class.perform_in(delay.from_now)

      log_extra_metadata_on_done(:delete_postponed, delay)

      return
    end

    # If a user accidentally attempts to delete the same container registry in quick succession,
    # this can lead to orphaned tags.
    try_obtain_lease do
      Projects::ContainerRepository::DestroyService.new(project, current_user).execute(container_repository)
    end
  end

  private

  def migrating?
    !(container_repository.default? ||
      container_repository.import_done? ||
      container_repository.import_skipped?)
  end

  def migration_duration
    duration = migration.import_timeout.seconds + FIXED_DELAY

    if container_repository.pre_importing?
      duration += migration.dynamic_pre_import_timeout_for(container_repository)
    end

    duration
  end

  def migration
    ContainerRegistry::Migration
  end

  # For ExclusiveLeaseGuard concern
  def lease_key
    @lease_key ||= "container_repository:delete:#{container_repository.id}"
  end

  # For ExclusiveLeaseGuard concern
  def lease_timeout
    LEASE_TIMEOUT
  end
end

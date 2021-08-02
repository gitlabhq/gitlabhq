# frozen_string_literal: true

module GitGarbageCollectMethods
  extend ActiveSupport::Concern

  included do
    include ApplicationWorker

    sidekiq_options retry: false
    feature_category :gitaly
    loggable_arguments 1, 2, 3
  end

  # Timeout set to 24h
  LEASE_TIMEOUT = 86400

  def perform(resource_id, task = :gc, lease_key = nil, lease_uuid = nil)
    resource = find_resource(resource_id)
    lease_key ||= default_lease_key(task, resource)
    active_uuid = get_lease_uuid(lease_key)

    if active_uuid
      return unless active_uuid == lease_uuid

      renew_lease(lease_key, active_uuid)
    else
      lease_uuid = try_obtain_lease(lease_key)

      return unless lease_uuid
    end

    task = task.to_sym

    before_gitaly_call(task, resource)
    gitaly_call(task, resource)

    # Refresh the branch cache in case garbage collection caused a ref lookup to fail
    flush_ref_caches(resource) if gc?(task)

    update_repository_statistics(resource) if task != :pack_refs

    # In case pack files are deleted, release libgit2 cache and open file
    # descriptors ASAP instead of waiting for Ruby garbage collection
    resource.cleanup
  ensure
    cancel_lease(lease_key, lease_uuid) if lease_key.present? && lease_uuid.present?
  end

  private

  def default_lease_key(task, resource)
    "git_gc:#{task}:#{resource.class.name.underscore.pluralize}:#{resource.id}"
  end

  def find_resource(id)
    raise NotImplementedError
  end

  def gc?(task)
    task == :gc || task == :prune
  end

  def try_obtain_lease(key)
    ::Gitlab::ExclusiveLease.new(key, timeout: LEASE_TIMEOUT).try_obtain
  end

  def renew_lease(key, uuid)
    ::Gitlab::ExclusiveLease.new(key, uuid: uuid, timeout: LEASE_TIMEOUT).renew
  end

  def cancel_lease(key, uuid)
    ::Gitlab::ExclusiveLease.cancel(key, uuid)
  end

  def get_lease_uuid(key)
    ::Gitlab::ExclusiveLease.get_uuid(key)
  end

  def before_gitaly_call(task, resource)
    # no-op
  end

  def gitaly_call(task, resource)
    repository = resource.repository.raw_repository

    client = get_gitaly_client(task, repository)

    case task
    when :prune, :gc
      client.garbage_collect(bitmaps_enabled?, prune: task == :prune)
    when :full_repack
      client.repack_full(bitmaps_enabled?)
    when :incremental_repack
      client.repack_incremental
    when :pack_refs
      client.pack_refs
    end
  rescue GRPC::NotFound => e
    Gitlab::GitLogger.error("#{__method__} failed:\nRepository not found")
    raise Gitlab::Git::Repository::NoRepository, e
  rescue GRPC::BadStatus => e
    Gitlab::GitLogger.error("#{__method__} failed:\n#{e}")
    raise Gitlab::Git::CommandError, e
  end

  def get_gitaly_client(task, repository)
    if task == :pack_refs
      Gitlab::GitalyClient::RefService
    else
      Gitlab::GitalyClient::RepositoryService
    end.new(repository)
  end

  def bitmaps_enabled?
    Gitlab::CurrentSettings.housekeeping_bitmaps_enabled
  end

  def flush_ref_caches(resource)
    resource.repository.expire_branches_cache
    resource.repository.branch_names
    resource.repository.has_visible_content?
  end

  def update_repository_statistics(resource)
    resource.repository.expire_statistics_caches

    return if Gitlab::Database.read_only? # GitGarbageCollectWorker may be run on a Geo secondary

    update_db_repository_statistics(resource)
  end

  def update_db_repository_statistics(resource)
    # no-op
  end
end

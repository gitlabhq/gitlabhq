# frozen_string_literal: true

class GitGarbageCollectWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  sidekiq_options retry: false
  feature_category :gitaly
  loggable_arguments 1, 2, 3

  # Timeout set to 24h
  LEASE_TIMEOUT = 86400

  def perform(project_id, task = :gc, lease_key = nil, lease_uuid = nil)
    lease_key ||= "git_gc:#{task}:#{project_id}"
    project = Project.find(project_id)
    active_uuid = get_lease_uuid(lease_key)

    if active_uuid
      return unless active_uuid == lease_uuid

      renew_lease(lease_key, active_uuid)
    else
      lease_uuid = try_obtain_lease(lease_key)

      return unless lease_uuid
    end

    task = task.to_sym

    if gc?(task)
      ::Projects::GitDeduplicationService.new(project).execute
      cleanup_orphan_lfs_file_references(project)
    end

    gitaly_call(task, project)

    # Refresh the branch cache in case garbage collection caused a ref lookup to fail
    flush_ref_caches(project) if gc?(task)

    update_repository_statistics(project) if task != :pack_refs

    # In case pack files are deleted, release libgit2 cache and open file
    # descriptors ASAP instead of waiting for Ruby garbage collection
    project.cleanup
  ensure
    cancel_lease(lease_key, lease_uuid) if lease_key.present? && lease_uuid.present?
  end

  private

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

  def gitaly_call(task, project)
    repository = project.repository.raw_repository

    client = if task == :pack_refs
               Gitlab::GitalyClient::RefService.new(repository)
             else
               Gitlab::GitalyClient::RepositoryService.new(repository)
             end

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
    raise Gitlab::Git::Repository::NoRepository.new(e)
  rescue GRPC::BadStatus => e
    Gitlab::GitLogger.error("#{__method__} failed:\n#{e}")
    raise Gitlab::Git::CommandError.new(e)
  end

  def cleanup_orphan_lfs_file_references(project)
    return if Gitlab::Database.read_only? # GitGarbageCollectWorker may be run on a Geo secondary

    ::Gitlab::Cleanup::OrphanLfsFileReferences.new(project, dry_run: false, logger: logger).run!
  rescue => err
    Gitlab::GitLogger.warn(message: "Cleaning up orphan LFS objects files failed", error: err.message)
    Gitlab::ErrorTracking.track_and_raise_for_dev_exception(err)
  end

  def flush_ref_caches(project)
    project.repository.expire_branches_cache
    project.repository.branch_names
    project.repository.has_visible_content?
  end

  def update_repository_statistics(project)
    project.repository.expire_statistics_caches
    return if Gitlab::Database.read_only? # GitGarbageCollectWorker may be run on a Geo secondary

    Projects::UpdateStatisticsService.new(project, nil, statistics: [:repository_size, :lfs_objects_size]).execute
  end

  def bitmaps_enabled?
    Gitlab::CurrentSettings.housekeeping_bitmaps_enabled
  end
end

# frozen_string_literal: true

class GitGarbageCollectWorker
  include ApplicationWorker

  sidekiq_options retry: false

  # Timeout set to 24h
  LEASE_TIMEOUT = 86400

  def perform(project_id, task = :gc, lease_key = nil, lease_uuid = nil)
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

    ::Projects::GitDeduplicationService.new(project).execute

    gitaly_call(task, project.repository.raw_repository)

    # Refresh the branch cache in case garbage collection caused a ref lookup to fail
    flush_ref_caches(project) if task == :gc

    project.repository.expire_statistics_caches if task != :pack_refs

    # In case pack files are deleted, release libgit2 cache and open file
    # descriptors ASAP instead of waiting for Ruby garbage collection
    project.cleanup
  ensure
    cancel_lease(lease_key, lease_uuid) if lease_key.present? && lease_uuid.present?
  end

  private

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

  ## `repository` has to be a Gitlab::Git::Repository
  def gitaly_call(task, repository)
    client = if task == :pack_refs
               Gitlab::GitalyClient::RefService.new(repository)
             else
               Gitlab::GitalyClient::RepositoryService.new(repository)
             end

    case task
    when :gc
      client.garbage_collect(bitmaps_enabled?)
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

  def flush_ref_caches(project)
    project.repository.after_create_branch
    project.repository.branch_names
    project.repository.has_visible_content?
  end

  def bitmaps_enabled?
    Gitlab::CurrentSettings.housekeeping_bitmaps_enabled
  end
end

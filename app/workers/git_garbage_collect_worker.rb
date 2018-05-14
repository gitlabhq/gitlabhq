class GitGarbageCollectWorker
  include ApplicationWorker

  sidekiq_options retry: false

  # Timeout set to 24h
  LEASE_TIMEOUT = 86400

  GITALY_MIGRATED_TASKS = {
    gc: :garbage_collect,
    full_repack: :repack_full,
    incremental_repack: :repack_incremental
  }.freeze

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
    cmd = command(task)

    gitaly_migrate(GITALY_MIGRATED_TASKS[task]) do |is_enabled|
      if is_enabled
        gitaly_call(task, project.repository.raw_repository)
      else
        repo_path = project.repository.path_to_repo
        description = "'#{cmd.join(' ')}' in #{repo_path}"
        Gitlab::GitLogger.info(description)

        output, status = Gitlab::Popen.popen(cmd, repo_path)

        Gitlab::GitLogger.error("#{description} failed:\n#{output}") unless status.zero?
      end
    end

    # Refresh the branch cache in case garbage collection caused a ref lookup to fail
    flush_ref_caches(project) if task == :gc

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
    client = Gitlab::GitalyClient::RepositoryService.new(repository)
    case task
    when :gc
      client.garbage_collect(bitmaps_enabled?)
    when :full_repack
      client.repack_full(bitmaps_enabled?)
    when :incremental_repack
      client.repack_incremental
    end
  end

  def command(task)
    case task
    when :gc
      git(write_bitmaps: bitmaps_enabled?) + %w[gc]
    when :full_repack
      git(write_bitmaps: bitmaps_enabled?) + %w[repack -A -d --pack-kept-objects]
    when :incremental_repack
      # Normal git repack fails when bitmaps are enabled. It is impossible to
      # create a bitmap here anyway.
      git(write_bitmaps: false) + %w[repack -d]
    else
      raise "Invalid gc task: #{task.inspect}"
    end
  end

  def flush_ref_caches(project)
    project.repository.after_create_branch
    project.repository.branch_names
    project.repository.has_visible_content?
  end

  def bitmaps_enabled?
    Gitlab::CurrentSettings.housekeeping_bitmaps_enabled
  end

  def git(write_bitmaps:)
    config_value = write_bitmaps ? 'true' : 'false'
    %W[git -c repack.writeBitmaps=#{config_value}]
  end

  def gitaly_migrate(method, &block)
    Gitlab::GitalyClient.migrate(method, &block)
  rescue GRPC::NotFound => e
    Gitlab::GitLogger.error("#{method} failed:\nRepository not found")
    raise Gitlab::Git::Repository::NoRepository.new(e)
  rescue GRPC::BadStatus => e
    Gitlab::GitLogger.error("#{method} failed:\n#{e}")
    raise Gitlab::Git::CommandError.new(e)
  end
end
